# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWkbReadDataProvider class definition

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
#! Data provider for reading WKB (Well-Known Binary) geometry data
/** This data provider allows reading WKB geometry data from files, streams, or inline data
    using the DataProvider API. Supports two formats:
    - \c hex (default): one hex-encoded WKB string per line (common in PostGIS dumps)
    - \c binary: 4-byte big-endian uint32 length prefix followed by raw WKB bytes

    Input can be provided via:
    - \c path: a filesystem path or location URL (processed by FileLocationHandler)
    - \c stream: an InputStream object
    - \c data: inline data (string for hex format, binary for binary format)

    Each record returned contains:
    - \c geometry (binary): the raw WKB data
    - \c wkt (string): the WKT representation of the geometry
    - \c type (string): the geometry type (e.g., \c "Point", \c "Polygon")
    - \c record_number (int): the 1-based record number in the input

    @par Example: Read hex-encoded WKB file
    @code{.py}
    GEOSWkbReadDataProvider provider({"path": "geometries.wkb", "format": "hex"});
    AbstractDataProviderRecordIterator i = provider.searchRecords();
    map printf("record %d: %s (WKT: %s)\n", $1.record_number, $1.type, $1.wkt), i;
    @endcode

    @par Example: Read hex WKB from inline string data
    @code{.py}
    # Hex-encoded WKB for POINT (1 2) and POINT (3 4)
    string hex_data = make_hex_string(make_wkb(parse_wkt("POINT (1 2)"))) + "\n"
        + make_hex_string(make_wkb(parse_wkt("POINT (3 4)")));

    GEOSWkbReadDataProvider provider({"data": hex_data});
    map printf("%s\n", $1.wkt), provider.searchRecords();
    # output: POINT (1 2), POINT (3 4)
    @endcode

    @par Example: Read length-prefixed binary WKB
    @code{.py}
    GEOSWkbReadDataProvider provider({"path": "geometries.wkb", "format": "binary"});
    map printf("%s: %s\n", $1.type, $1.wkt), provider.searchRecords();
    @endcode
*/
public class GEOSWkbReadDataProvider inherits DataProvider::AbstractDataProvider {
    public {
        #! Provider info
        const ProviderInfo = <DataProviderInfo>{
            "name": "geoswkbread",
            "desc": "GEOS WKB data provider for reading Well-Known Binary geometry data",
            "type": "GEOSWkbReadDataProvider",
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
                "short_desc": "The path to the WKB file to read",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The filesystem path or location URL for the WKB file to read; the input "
                    "location is handled by a call to "
                    "[FileLocationHandler::getBinaryStreamFromLocation()]()",
            },
            "stream": <DataProviderOptionInfo>{
                "display_name": "Input Stream",
                "short_desc": "The input stream to read from",
                "type": AbstractDataProviderTypeMap."any",
                "desc": "An input stream to read WKB data from",
            },
            "data": <DataProviderOptionInfo>{
                "display_name": "Data",
                "short_desc": "WKB data as a string (hex) or binary",
                "type": AbstractDataProviderTypeMap."any",
                "desc": "WKB data provided directly; string data is treated as hex-encoded lines, "
                    "binary data is treated according to the format option",
            },
            "format": <DataProviderOptionInfo>{
                "display_name": "Format",
                "short_desc": "WKB data format",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The WKB data format: `hex` (default) for hex-encoded lines, "
                    "`binary` for length-prefixed binary",
                "default_value": "hex",
                "allowed_values": (
                    <AllowedValueInfo>{
                        "value": "hex",
                        "desc": "Hex-encoded WKB data, one geometry per line (default)",
                    },
                    <AllowedValueInfo>{
                        "value": "binary",
                        "desc": "Length-prefixed binary WKB data (4-byte big-endian uint32 length + raw WKB)",
                    },
                ),
            },
            "skip_empty_lines": <DataProviderOptionInfo>{
                "display_name": "Skip Empty Lines",
                "short_desc": "Skip empty lines in hex mode",
                "type": AbstractDataProviderTypeMap."bool",
                "desc": "If `True` (default), empty lines are skipped during iteration in hex mode",
                "default_value": True,
            },
            "encoding": <DataProviderOptionInfo>{
                "display_name": "Encoding",
                "short_desc": "Character encoding for hex mode",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The character encoding to use when reading hex data (default: UTF-8)",
                "default_value": DefaultEncoding,
            },
        };

        #! Record type for WKB read records
        const RecordType = new HashDataType("GEOSWkbReadRecord", {
            "geometry": {
                "display_name": "Geometry",
                "short_desc": "The WKB geometry data",
                "desc": "The Well-Known Binary representation of the geometry",
                "type": DataType,
            },
            "wkt": {
                "display_name": "WKT",
                "short_desc": "The WKT representation of the geometry",
                "desc": "The Well-Known Text representation of the geometry",
                "type": StringType,
            },
            "type": {
                "display_name": "Geometry Type",
                "short_desc": "The type of the geometry",
                "desc": "The geometry type (e.g., Point, LineString, Polygon)",
                "type": StringType,
            },
            "record_number": {
                "display_name": "Record Number",
                "short_desc": "The record number in the input",
                "desc": "The 1-based record number of the geometry in the input",
                "type": IntType,
            },
        });
    }

    private {
        #! The file path
        *string path;

        #! The input stream
        *Qore::InputStream stream;

        #! The data (string for hex, binary for binary)
        auto data;

        #! The format
        string format = "hex";

        #! Skip empty lines
        bool skip_empty_lines = True;

        #! Encoding
        string encoding = DefaultEncoding;
    }

    #! Creates the provider from options
    /** @param options provider options; one of path, stream, or data must be provided

        @throw GEOS-WKB-ERROR if no input source is provided or invalid format
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
        if (exists options.format) {
            format = options.format;
        }
        if (exists options.skip_empty_lines) {
            skip_empty_lines = options.skip_empty_lines;
        }
        if (exists options.encoding) {
            encoding = options.encoding;
        }
        if (!exists path && !exists stream && !exists data) {
            throw "GEOS-WKB-ERROR", "one of 'path', 'stream', or 'data' must be provided";
        }
        if (format != "hex" && format != "binary") {
            throw "GEOS-WKB-ERROR", sprintf("invalid format %y; expected 'hex' or 'binary'", format);
        }
    }

    #! Returns the data provider name
    string getName() {
        return path ?? "geoswkbread";
    }

    #! Returns the data provider description
    *string getDesc() {
        if (path) {
            return sprintf("GEOS WKB data provider for file: %s", path);
        }
        return "GEOS WKB data provider";
    }

    #! Returns an iterator for the records
    private AbstractDataProviderRecordIterator searchRecordsImpl(*hash<auto> where_cond,
            *hash<auto> search_options) {
        return new GEOSWkbRecordIterator(getIterator());
    }

    #! Creates and returns the appropriate iterator
    private AbstractIterator getIterator() {
        Qore::InputStream is;
        if (exists data) {
            if (data.typeCode() == NT_BINARY) {
                is = new BinaryInputStream(data);
            } else {
                is = new StringInputStream(data);
            }
        } else if (exists stream) {
            is = stream;
        } else {
            is = FileLocationHandler::getBinaryStreamFromLocation(path);
        }
        return new GEOSWkbIterator(is, format, encoding, skip_empty_lines);
    }

    #! Returns the record type
    private *AbstractDataProviderType getRecordTypeImpl() {
        return RecordType;
    }

    #! Returns static provider info
    private hash<DataProviderInfo> getStaticInfoImpl() {
        return ProviderInfo;
    }
}

#! Record iterator wrapper for WKB geometry data
public class GEOSWkbRecordIterator inherits DataProvider::AbstractDataProviderRecordIterator {
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
    *AbstractDataProviderType getRecordType() {
        return GEOSWkbReadDataProvider::RecordType;
    }
}
}
