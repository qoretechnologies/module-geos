# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWkbIterator class definition

/*  Copyright 2026 Qore Technologies, s.r.o.

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*/

#! Contains all public definitions in the GEOSDataProvider module
public namespace GEOSDataProvider {
#! Iterator for reading WKB (Well-Known Binary) geometry data from an input stream
/** This class provides an iterator interface for reading WKB formatted geometry data
    from an input stream. Supports two formats:
    - \c hex (default): one hex-encoded WKB string per line (common in PostGIS dumps);
      empty lines are skipped by default
    - \c binary: 4-byte big-endian uint32 length prefix followed by raw WKB bytes

    Each value returned by getValue() is a hash with:
    - \c geometry (binary): the raw WKB data
    - \c wkt (string): the WKT representation of the geometry
    - \c type (string): the geometry type (e.g., \c "Point", \c "LineString", \c "Polygon")
    - \c record_number (int): the 1-based record number in the input

    @par Example: Read hex-encoded WKB from a file
    @code{.py}
    FileInputStream fis("geometries.wkb");
    GEOSWkbIterator iter(fis, "hex");
    while (iter.next()) {
        hash<auto> record = iter.getValue();
        printf("record %d: %s (WKT: %s)\n", record.record_number, record.type, record.wkt);
    }
    @endcode

    @par Example: Read length-prefixed binary WKB
    @code{.py}
    FileInputStream fis("geometries.bin");
    GEOSWkbIterator iter(fis, "binary");
    map printf("%s: %s\n", $1.type, $1.wkt), iter;
    @endcode
*/
public class GEOSWkbIterator inherits AbstractIterator {
    private {
        #! The input stream (for binary mode)
        Qore::InputStream input_stream;

        #! The stream reader (for hex mode)
        *Qore::StreamReader reader;

        #! Format: "hex" or "binary"
        string format;

        #! Current record value
        hash<auto> current_value;

        #! Current record number (1-based)
        int record_number = 0;

        #! Whether to skip empty lines (hex mode only)
        bool skip_empty_lines;

        #! Valid flag
        bool is_valid = False;

        #! End of stream flag
        bool eos = False;
    }

    #! Creates the iterator from an input stream
    /** @param is the input stream to read WKB data from
        @param fmt the format: \c "hex" (default) for hex-encoded lines, \c "binary" for length-prefixed binary
        @param encoding the character encoding for hex mode (default: UTF-8)
        @param skip_empty whether to skip empty lines in hex mode (default: True)

        @throw GEOS-WKB-ERROR if the format is invalid
    */
    constructor(Qore::InputStream is, string fmt = "hex", string encoding = DefaultEncoding,
            bool skip_empty = True) {
        if (fmt != "hex" && fmt != "binary") {
            throw "GEOS-WKB-ERROR", sprintf("invalid format %y; expected 'hex' or 'binary'", fmt);
        }
        input_stream = is;
        format = fmt;
        skip_empty_lines = skip_empty;
        if (format == "hex") {
            reader = new StreamReader(is, encoding);
        }
    }

    #! Advances to the next WKB geometry
    /** @return True if there is a next geometry, False if iteration is complete

        @throw GEOS-WKB-ERROR if WKB parsing fails
    */
    bool next() {
        if (eos) {
            return False;
        }

        if (format == "hex") {
            return nextHex();
        }
        return nextBinary();
    }

    #! Reads the next hex-encoded WKB line
    private bool nextHex() {
        while (True) {
            record_number++;

            *string line = reader.readLine();

            if (!exists line) {
                eos = True;
                is_valid = False;
                current_value = {};
                return False;
            }

            # Remove trailing CR if present (CRLF case)
            if (line.size() > 0 && line[line.size() - 1] == "\r") {
                line = line.substr(0, line.size() - 1);
            }

            # Handle empty lines
            if (line.empty() || line =~ /^\s*$/) {
                if (skip_empty_lines) {
                    continue;
                }
                throw "GEOS-WKB-ERROR", sprintf("empty WKB hex data at record %d", record_number);
            }

            # Trim whitespace
            line = trim(line);

            # Decode hex to binary
            binary wkb;
            try {
                wkb = parse_hex_string(line);
            } catch (hash<ExceptionInfo> ex) {
                throw "GEOS-WKB-ERROR", sprintf("failed to decode hex at record %d: %s",
                    record_number, ex.desc), ex;
            }

            # Parse WKB
            GEOSGeometry geom;
            try {
                geom = parse_wkb(wkb);
            } catch (hash<ExceptionInfo> ex) {
                throw "GEOS-WKB-ERROR", sprintf("failed to parse WKB at record %d: %s",
                    record_number, ex.desc), ex;
            }

            current_value = {
                "geometry": wkb,
                "wkt": make_wkt(geom),
                "type": geom.geometryType(),
                "record_number": record_number,
            };
            is_valid = True;
            return True;
        }
    }

    #! Reads the next length-prefixed binary WKB record
    private bool nextBinary() {
        record_number++;

        # Read 4-byte big-endian length prefix
        *binary len_data = input_stream.read(4);
        if (!exists len_data || len_data.size() == 0) {
            eos = True;
            is_valid = False;
            current_value = {};
            return False;
        }
        if (len_data.size() < 4) {
            throw "GEOS-WKB-ERROR", sprintf("incomplete length prefix at record %d: expected 4 bytes, got %d",
                record_number, len_data.size());
        }

        # Decode big-endian uint32 length
        int len = (get_byte(len_data, 0) << 24) | (get_byte(len_data, 1) << 16)
            | (get_byte(len_data, 2) << 8) | get_byte(len_data, 3);

        if (len <= 0) {
            throw "GEOS-WKB-ERROR", sprintf("invalid WKB length %d at record %d", len, record_number);
        }

        # Read WKB data
        binary wkb = binary();
        while (wkb.size() < len) {
            *binary chunk = input_stream.read(len - wkb.size());
            if (!exists chunk || chunk.size() == 0) {
                throw "GEOS-WKB-ERROR", sprintf("unexpected end of stream at record %d: expected %d bytes, got %d",
                    record_number, len, wkb.size());
            }
            wkb += chunk;
        }

        # Parse WKB
        GEOSGeometry geom;
        try {
            geom = parse_wkb(wkb);
        } catch (hash<ExceptionInfo> ex) {
            throw "GEOS-WKB-ERROR", sprintf("failed to parse WKB at record %d: %s",
                record_number, ex.desc), ex;
        }

        current_value = {
            "geometry": wkb,
            "wkt": make_wkt(geom),
            "type": geom.geometryType(),
            "record_number": record_number,
        };
        is_valid = True;
        return True;
    }

    #! Returns the current record value
    /** @return a hash with keys: \c geometry (binary WKB), \c wkt (string WKT), \c type (geometry type),
        \c record_number (int)

        @throw ITERATOR-ERROR if the iterator is not valid
    */
    hash<auto> getValue() {
        if (!is_valid) {
            throw "ITERATOR-ERROR", "iterator is not valid; call next() first";
        }
        return current_value;
    }

    #! Returns True if the iterator is valid
    bool valid() {
        return is_valid;
    }

    #! Returns the current record number (1-based)
    int getRecordNumber() {
        return record_number;
    }
}
}
