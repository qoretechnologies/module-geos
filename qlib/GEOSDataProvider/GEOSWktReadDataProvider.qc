# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWktReadDataProvider class definition

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
#! Data provider for reading WKT (Well-Known Text) geometry data
/** This data provider allows reading WKT geometry data from files, streams, or strings
    using the DataProvider API. Each line in the input is expected to contain a single WKT
    geometry.

    Input can be provided via:
    - \c path: a filesystem path or location URL (processed by FileLocationHandler)
    - \c stream: an InputStream object
    - \c data: a string containing WKT data directly

    Each record returned contains:
    - \c geometry (string): the WKT geometry string
    - \c type (string): the geometry type (e.g., \c "Point", \c "Polygon")
    - \c line_number (int): the 1-based line number in the input

    @par Example: Read from a file
    @code{.py}
    GEOSWktReadDataProvider provider({"path": "geometries.wkt"});
    AbstractDataProviderRecordIterator i = provider.searchRecords();
    map printf("line %d: %s (%s)\n", $1.line_number, $1.geometry, $1.type), i;
    @endcode

    @par Example: Read from inline string data
    @code{.py}
    string wkt_data = "POINT (1 2)\nLINESTRING (0 0, 1 1)\nPOLYGON ((0 0, 1 0, 1 1, 0 0))";
    GEOSWktReadDataProvider provider({"data": wkt_data});
    map printf("%s\n", $1.type), provider.searchRecords();
    # output: Point, LineString, Polygon
    @endcode
*/
public class GEOSWktReadDataProvider inherits DataProvider::AbstractDataProvider {
    public {
        #! Provider info
        const ProviderInfo = <DataProviderInfo>{
            "name": "geoswktread",
            "desc": "GEOS WKT data provider for reading Well-Known Text geometry data",
            "type": "GEOSWktReadDataProvider",
            "supports_read": True,
            "supports_request": False,
            "has_record": True,
            "supports_search_expressions": True,
            "constructor_options": ConstructorOptions,
        };

        #! Constructor options
        const ConstructorOptions = {
            "path": <DataProviderOptionInfo>{
                "display_name": "File Path",
                "short_desc": "The path to the WKT file to read",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The filesystem path or location URL for the WKT file to read; the input "
                    "location is handled by a call to "
                    "[FileLocationHandler::getBinaryStreamFromLocation()]()",
            },
            "stream": <DataProviderOptionInfo>{
                "display_name": "Input Stream",
                "short_desc": "The input stream to read from",
                "type": AbstractDataProviderTypeMap."any",
                "desc": "An input stream to read WKT data from",
            },
            "data": <DataProviderOptionInfo>{
                "display_name": "Data",
                "short_desc": "WKT data as a string",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "WKT data provided directly as a string; each line should contain one WKT geometry",
            },
            "skip_empty_lines": <DataProviderOptionInfo>{
                "display_name": "Skip Empty Lines",
                "short_desc": "Skip empty lines in the input",
                "type": AbstractDataProviderTypeMap."bool",
                "desc": "If `True` (default), empty lines are skipped during iteration",
                "default_value": True,
            },
            "encoding": <DataProviderOptionInfo>{
                "display_name": "Encoding",
                "short_desc": "Character encoding for the input",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The character encoding to use when reading the input (default: UTF-8)",
                "default_value": DefaultEncoding,
            },
        };

        #! Record type for WKT read records
        const RecordType = new HashDataType("GEOSWktReadRecord", {
            "geometry": {
                "display_name": "Geometry",
                "short_desc": "The WKT geometry string",
                "desc": "The Well-Known Text representation of the geometry",
                "type": StringType,
            },
            "type": {
                "display_name": "Geometry Type",
                "short_desc": "The type of the geometry",
                "desc": "The geometry type (e.g., Point, LineString, Polygon)",
                "type": StringType,
            },
            "line_number": {
                "display_name": "Line Number",
                "short_desc": "The line number in the input",
                "desc": "The 1-based line number of the geometry in the input",
                "type": IntType,
            },
        });
    }

    private {
        #! The file path
        *string path;

        #! The input stream
        *Qore::InputStream stream;

        #! The string data
        *string data;

        #! Skip empty lines
        bool skip_empty_lines = True;

        #! Encoding
        string encoding = DefaultEncoding;
    }

    #! Creates the provider from options
    /** @param options provider options; one of path, stream, or data must be provided

        @throw GEOS-WKT-ERROR if no input source is provided
    */
    constructor(*hash<auto> options) {
        if (exists options.path) {
            path = options.path;
        }
        if (exists options.stream) {
            stream = options.stream;
        }
        if (exists options.data) {
            data = options.data;
        }
        if (exists options.skip_empty_lines) {
            skip_empty_lines = options.skip_empty_lines;
        }
        if (exists options.encoding) {
            encoding = options.encoding;
        }
        if (!exists path && !exists stream && !exists data) {
            throw "GEOS-WKT-ERROR", "one of 'path', 'stream', or 'data' must be provided";
        }
    }

    #! Returns the data provider name
    string getName() {
        return path ?? "geoswktread";
    }

    #! Returns the data provider description
    *string getDesc() {
        if (path) {
            return sprintf("GEOS WKT data provider for file: %s", path);
        }
        return "GEOS WKT data provider";
    }

    #! Returns an iterator for the records
    private AbstractDataProviderRecordIterator searchRecordsImpl(*hash<auto> where_cond,
            *hash<auto> search_options) {
        return new GEOSWktRecordIterator(getIterator());
    }

    #! Creates and returns the appropriate iterator
    private AbstractIterator getIterator() {
        Qore::InputStream is;
        if (exists data) {
            is = new StringInputStream(data);
        } else if (exists stream) {
            is = stream;
        } else {
            is = FileLocationHandler::getBinaryStreamFromLocation(path);
        }
        return new GEOSWktIterator(is, encoding, skip_empty_lines);
    }

    #! Returns the record type
    private *hash<string, AbstractDataField> getRecordTypeImpl(*hash<auto> search_options) {
        return RecordType.getFields();
    }

    #! Returns static provider info
    private hash<DataProviderInfo> getStaticInfoImpl() {
        return ProviderInfo;
    }
}

#! Record iterator wrapper for WKT geometry data
public class GEOSWktRecordIterator inherits DataProvider::AbstractDataProviderRecordIterator {
    private {
        #! The underlying iterator
        AbstractIterator iter;
    }

    #! Creates the record iterator
    constructor(AbstractIterator iterator) {
        iter = iterator;
    }

    #! Advances to the next record
    private bool nextImpl() {
        return iter.next();
    }

    #! Returns the current record value
    hash<auto> getValue() {
        return iter.getValue();
    }

    #! Returns True if the iterator is valid
    bool valid() {
        return iter.valid();
    }

    #! Returns the record type
    *hash<string, AbstractDataField> getRecordType() {
        return GEOSWktReadDataProvider::RecordType.getFields();
    }
}
}
