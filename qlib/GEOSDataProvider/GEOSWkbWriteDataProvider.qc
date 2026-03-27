# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWkbWriteDataProvider class definition

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
#! Data provider for writing WKB (Well-Known Binary) geometry data
/** This data provider allows writing WKB geometry data to files or streams
    using the DataProvider API. Supports two output formats:
    - \c hex (default): one hex-encoded WKB string per line
    - \c binary: 4-byte big-endian uint32 length prefix followed by raw WKB bytes

    Output can be directed to:
    - \c path: a filesystem path or location URL (processed by FileLocationHandler)
    - \c stream: an OutputStream object

    Each record must contain:
    - \c geometry: the geometry to write; accepts either binary WKB data or a string WKT value
      (WKT is automatically converted to WKB)

    @par Example: Write hex-encoded WKB to a file
    @code{.py}
    GEOSWkbWriteDataProvider provider({"path": "output.wkb", "format": "hex"});
    # Write binary WKB data
    provider.createRecord({"geometry": make_wkb(parse_wkt("POINT (1 2)"))});
    # Also accepts WKT strings (auto-converts to WKB)
    provider.createRecord({"geometry": "LINESTRING (0 0, 1 1, 2 2)"});
    @endcode

    @par Example: Write length-prefixed binary WKB
    @code{.py}
    GEOSWkbWriteDataProvider provider({"path": "output.wkb", "format": "binary"});
    provider.createRecord({"geometry": "POINT (1 2)"});
    provider.createRecord({"geometry": "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))"});
    @endcode

    @par Example: WKT-to-WKB conversion pipeline
    @code{.py}
    # Read WKT and write as WKB hex
    GEOSWktReadDataProvider reader({"path": "input.wkt"});
    GEOSWkbWriteDataProvider writer({"path": "output.wkb"});
    map writer.createRecord({"geometry": $1.geometry}), reader.searchRecords();
    @endcode
*/
public class GEOSWkbWriteDataProvider inherits DataProvider::AbstractDataProvider {
    public {
        #! Provider info
        const ProviderInfo = <DataProviderInfo>{
            "name": "geoswkbwrite",
            "desc": "GEOS WKB data provider for writing Well-Known Binary geometry data",
            "type": "GEOSWkbWriteDataProvider",
            "supports_create": True,
            "supports_request": False,
            "has_record": True,
            "constructor_options": ConstructorOptions,
        };

        #! Constructor options
        const ConstructorOptions = {
            "path": <DataProviderOptionInfo>{
                "display_name": "Output Path",
                "short_desc": "The path to the output WKB file",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The filesystem path or location URL for the WKB output file; the output "
                    "location is handled by a call to "
                    "[FileLocationHandler::getOutputStreamForLocation()]()",
            },
            "stream": <DataProviderOptionInfo>{
                "display_name": "Output Stream",
                "short_desc": "The output stream to write to",
                "type": AbstractDataProviderTypeMap."any",
                "desc": "An output stream to write WKB data to",
            },
            "format": <DataProviderOptionInfo>{
                "display_name": "Format",
                "short_desc": "WKB output format",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The WKB output format: `hex` (default) for hex-encoded lines, "
                    "`binary` for length-prefixed binary",
                "default_value": "hex",
                "allowed_values": (
                    <AllowedValueInfo>{
                        "display_name": "Hex",
                        "value": "hex",
                        "desc": "Hex-encoded WKB data, one geometry per line (default)",
                    },
                    <AllowedValueInfo>{
                        "display_name": "Binary",
                        "value": "binary",
                        "desc": "Length-prefixed binary WKB data (4-byte big-endian uint32 length + raw WKB)",
                    },
                ),
            },
            "encoding": <DataProviderOptionInfo>{
                "display_name": "Encoding",
                "short_desc": "Character encoding for hex mode",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The character encoding to use when writing hex data (default: UTF-8)",
                "default_value": DefaultEncoding,
            },
        };

        #! Record type for WKB write records
        const RecordType = new HashDataType("GEOSWkbWriteRecord", {
            "geometry": {
                "display_name": "Geometry",
                "short_desc": "The geometry data (binary WKB or string WKT)",
                "desc": "The geometry to write; accepts binary WKB data or a string WKT value "
                    "(WKT is automatically converted to WKB)",
                "type": AutoType,
            },
        });
    }

    private {
        #! The output stream
        Qore::OutputStream output_stream;

        #! The stream writer (for hex mode)
        *Qore::StreamWriter writer;

        #! Format: "hex" or "binary"
        string format;
    }

    #! Creates the provider from options
    /** @param options provider options; one of path or stream must be provided

        @throw GEOS-WKB-ERROR if no output target is provided or invalid format
    */
    constructor(*hash<auto> options) {
        format = options.format ?? "hex";
        if (format != "hex" && format != "binary") {
            throw "GEOS-WKB-ERROR", sprintf("invalid format %y; expected 'hex' or 'binary'", format);
        }
        string encoding = options.encoding ?? DefaultEncoding;
        if (exists options.path) {
            output_stream = FileLocationHandler::getOutputStreamForLocation(options.path);
        } else if (exists options.stream) {
            output_stream = options.stream;
        } else {
            throw "GEOS-WKB-ERROR", "one of 'path' or 'stream' must be provided";
        }
        if (format == "hex") {
            writer = new StreamWriter(output_stream, encoding);
        }
    }

    #! Returns the data provider name
    string getName() {
        return "geoswkbwrite";
    }

    #! Returns the data provider description
    *string getDesc() {
        return "GEOS WKB data provider for writing geometry data";
    }

    #! Creates a record (writes a WKB geometry)
    /** @param rec a hash with a \c geometry key containing binary WKB or string WKT
        @param create_options not used

        @return the record written

        @throw GEOS-WKB-ERROR if the geometry is invalid
    */
    private *hash<auto> createRecordImpl(hash<auto> rec, *hash<auto> create_options) {
        binary wkb;
        if (rec.geometry.typeCode() == NT_BINARY) {
            wkb = rec.geometry;
            # Validate by parsing
            parse_wkb(wkb);
        } else if (rec.geometry.typeCode() == NT_STRING) {
            # Auto-convert WKT to WKB
            GEOSGeometry geom = parse_wkt(rec.geometry);
            wkb = make_wkb(geom);
        } else {
            throw "GEOS-WKB-ERROR", sprintf("geometry must be binary (WKB) or string (WKT), got type %y",
                rec.geometry.type());
        }

        if (format == "hex") {
            writer.write(make_hex_string(wkb) + "\n");
        } else {
            # Write 4-byte big-endian length prefix
            int len = wkb.size();
            binary len_data = binary();
            len_data += <00>;
            len_data += <00>;
            len_data += <00>;
            len_data += <00>;
            # Set bytes manually for big-endian uint32
            splice len_data, 0, 1, chr(len >> 24 & 0xff);
            splice len_data, 1, 1, chr(len >> 16 & 0xff);
            splice len_data, 2, 1, chr(len >> 8 & 0xff);
            splice len_data, 3, 1, chr(len & 0xff);
            output_stream.write(len_data);
            output_stream.write(wkb);
        }
        return rec;
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
}
