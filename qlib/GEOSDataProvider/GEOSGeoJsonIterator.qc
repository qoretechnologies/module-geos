# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSGeoJsonIterator class definition

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
#! Iterator for GeoJSON geometry data read line by line
/** Each line is expected to contain a single GeoJSON geometry object.
    Lines are parsed using @ref parse_geojson() and the resulting geometry
    type is extracted.

    @since geos 1.1
*/
public class GEOSGeoJsonIterator inherits AbstractIterator {
    private {
        #! The stream reader
        Qore::StreamReader reader;

        #! The current record value
        hash<auto> current_value;

        #! Current line number (1-based)
        int line_number = 0;

        #! Whether to skip empty lines
        bool skip_empty_lines;

        #! Whether the iterator is in a valid state
        bool is_valid = False;

        #! End of stream flag
        bool eos = False;
    }

    #! Creates the iterator from an input stream
    /** @param input_stream the stream to read GeoJSON lines from
        @param encoding the character encoding (default: UTF-8)
        @param skip_empty whether to skip empty lines (default: True)
    */
    constructor(Qore::InputStream input_stream, string encoding = DefaultEncoding,
            bool skip_empty = True) {
        reader = new StreamReader(input_stream, encoding);
        skip_empty_lines = skip_empty;
    }

    #! Advances to the next record
    /** @return True if a record was read, False at end of stream

        @throw GEOS-GEOJSON-ERROR if a line cannot be parsed as GeoJSON
    */
    bool next() {
        if (eos) {
            is_valid = False;
            return False;
        }

        while (True) {
            *string line = reader.readLine("\n");
            if (!exists line) {
                eos = True;
                is_valid = False;
                return False;
            }
            ++line_number;

            # strip trailing CR for Windows line endings
            if (line.size() > 0 && line[line.size() - 1] == "\r") {
                line = line.substr(0, line.size() - 1);
            }

            # skip empty lines
            string trimmed = trim(line);
            if (!trimmed.size()) {
                if (skip_empty_lines) {
                    continue;
                }
                throw "GEOS-GEOJSON-ERROR", sprintf("empty line at line %d", line_number);
            }

            # parse the GeoJSON
            GEOSGeometry geom;
            try {
                geom = parse_geojson(trimmed);
            } catch (hash<ExceptionInfo> ex) {
                throw "GEOS-GEOJSON-ERROR",
                    sprintf("failed to parse GeoJSON at line %d: %s", line_number, ex.desc);
            }
            current_value = {
                "geometry": trimmed,
                "type": geom.geometryType(),
                "line_number": line_number,
            };
            is_valid = True;
            return True;
        }
    }

    #! Returns the current record
    /** @return a hash with \c geometry, \c type, and \c line_number keys

        @throw ITERATOR-ERROR if the iterator is not in a valid state
    */
    hash<auto> getValue() {
        if (!is_valid) {
            throw "ITERATOR-ERROR", "iterator is not in a valid position";
        }
        return current_value;
    }

    #! Returns True if the iterator is in a valid state
    bool valid() {
        return is_valid;
    }

    #! Returns the current line number
    int getLineNumber() {
        return line_number;
    }
}
}
