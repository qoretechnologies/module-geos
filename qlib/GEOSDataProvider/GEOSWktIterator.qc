# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWktIterator class definition

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
#! Iterator for reading WKT (Well-Known Text) geometry data from an input stream
/** This class provides an iterator interface for reading WKT formatted geometry data
    from an input stream, one geometry per line. Empty lines are skipped by default.

    Each value returned by getValue() is a hash with:
    - \c geometry (string): the WKT geometry string
    - \c type (string): the geometry type (e.g., \c "Point", \c "LineString", \c "Polygon")
    - \c line_number (int): the 1-based line number in the input

    @par Example: Read from a file stream
    @code{.py}
    FileInputStream fis("geometries.wkt");
    GEOSWktIterator iter(fis);
    while (iter.next()) {
        hash<auto> record = iter.getValue();
        printf("line %d: %s (%s)\n", record.line_number, record.type, record.geometry);
    }
    @endcode

    @par Example: Read from a string
    @code{.py}
    StringInputStream sis("POINT (1 2)\nLINESTRING (0 0, 5 5)\nPOLYGON ((0 0, 1 0, 1 1, 0 0))");
    GEOSWktIterator iter(sis);
    map printf("%s\n", $1.type), iter;
    # output: Point, LineString, Polygon
    @endcode
*/
public class GEOSWktIterator inherits AbstractIterator {
    private {
        #! The stream reader
        Qore::StreamReader reader;

        #! Current record value
        hash<auto> current_value;

        #! Current line number (1-based)
        int line_number = 0;

        #! Whether to skip empty lines
        bool skip_empty_lines;

        #! Valid flag
        bool is_valid = False;

        #! End of stream flag
        bool eos = False;
    }

    #! Creates the iterator from an input stream
    /** @param input_stream the input stream to read WKT data from
        @param encoding the character encoding (default: UTF-8)
        @param skip_empty whether to skip empty lines (default: True)
    */
    constructor(Qore::InputStream input_stream, string encoding = DefaultEncoding, bool skip_empty = True) {
        reader = new StreamReader(input_stream, encoding);
        skip_empty_lines = skip_empty;
    }

    #! Advances to the next WKT geometry
    /** @return True if there is a next geometry, False if iteration is complete

        @throw GEOS-ERROR if WKT parsing fails
    */
    bool next() {
        if (eos) {
            return False;
        }

        while (True) {
            line_number++;

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
                throw "GEOS-WKT-ERROR", sprintf("empty WKT at line %d", line_number);
            }

            # Trim whitespace
            line = trim(line);

            # Parse WKT to validate
            GEOSGeometry geom;
            try {
                geom = parse_wkt(line);
            } catch (hash<ExceptionInfo> ex) {
                throw "GEOS-WKT-ERROR", sprintf("failed to parse WKT at line %d: %s", line_number, ex.desc), ex;
            }

            current_value = {
                "geometry": line,
                "type": geom.geometryType(),
                "line_number": line_number,
            };
            is_valid = True;
            return True;
        }
    }

    #! Returns the current record value
    /** @return a hash with keys: \c geometry (string WKT), \c type (geometry type), \c line_number (int)

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

    #! Returns the current line number (1-based)
    int getLineNumber() {
        return line_number;
    }
}
}
