# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWktWriteDataProvider class definition

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
#! Data provider for writing WKT (Well-Known Text) geometry data
/** This data provider allows writing WKT geometry data to files or streams
    using the DataProvider API. Each geometry is written as a single WKT line.

    Output can be directed to:
    - \c path: a filesystem path or location URL (processed by FileLocationHandler)
    - \c stream: an OutputStream object

    Each record must contain:
    - \c geometry (string): a valid WKT geometry string

    The geometry is validated by parsing it with \c parse_wkt() before writing.

    @par Example: Write to a file
    @code{.py}
    GEOSWktWriteDataProvider provider({"path": "output.wkt"});
    provider.createRecord({"geometry": "POINT (1 2)"});
    provider.createRecord({"geometry": "LINESTRING (0 0, 1 1, 2 2)"});
    provider.createRecord({"geometry": "POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))"});
    @endcode

    @par Example: Write to an in-memory stream
    @code{.py}
    StringOutputStream sos();
    GEOSWktWriteDataProvider provider({"stream": sos});
    provider.createRecord({"geometry": "POINT (1 2)"});
    provider.createRecord({"geometry": "POINT (3 4)"});
    string output = sos.getData();
    # output = "POINT (1 2)\nPOINT (3 4)\n"
    @endcode
*/
public class GEOSWktWriteDataProvider inherits DataProvider::AbstractDataProvider {
    public {
        #! Provider info
        const ProviderInfo = <DataProviderInfo>{
            "name": "geoswktwrite",
            "desc": "GEOS WKT data provider for writing Well-Known Text geometry data",
            "type": "GEOSWktWriteDataProvider",
            "supports_create": True,
            "supports_request": False,
            "has_record": True,
            "constructor_options": ConstructorOptions,
        };

        #! Constructor options
        const ConstructorOptions = {
            "path": <DataProviderOptionInfo>{
                "display_name": "Output Path",
                "short_desc": "The path to the output WKT file",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The filesystem path or location URL for the WKT output file; the output "
                    "location is handled by a call to "
                    "[FileLocationHandler::getOutputStreamForLocation()]()",
            },
            "stream": <DataProviderOptionInfo>{
                "display_name": "Output Stream",
                "short_desc": "The output stream to write to",
                "type": AbstractDataProviderTypeMap."any",
                "desc": "An output stream to write WKT data to",
            },
            "encoding": <DataProviderOptionInfo>{
                "display_name": "Encoding",
                "short_desc": "Character encoding for the output",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The character encoding to use when writing the output (default: UTF-8)",
                "default_value": DefaultEncoding,
            },
        };

        #! Record type for WKT write records
        const RecordType = new HashDataType("GEOSWktWriteRecord", {
            "geometry": {
                "display_name": "Geometry",
                "short_desc": "The WKT geometry string",
                "desc": "The Well-Known Text representation of the geometry to write",
                "type": StringType,
            },
        });
    }

    private {
        #! The stream writer
        Qore::StreamWriter writer;
    }

    #! Creates the provider from options
    /** @param options provider options; one of path or stream must be provided

        @throw GEOS-WKT-ERROR if no output target is provided
    */
    constructor(*hash<auto> options) {
        Qore::OutputStream os;
        string encoding = options.encoding ?? DefaultEncoding;
        if (exists options.path) {
            os = FileLocationHandler::getOutputStreamForLocation(options.path);
        } else if (exists options.stream) {
            os = options.stream;
        } else {
            throw "GEOS-WKT-ERROR", "one of 'path' or 'stream' must be provided";
        }
        writer = new StreamWriter(os, encoding);
    }

    #! Returns the data provider name
    string getName() {
        return "geoswktwrite";
    }

    #! Returns the data provider description
    *string getDesc() {
        return "GEOS WKT data provider for writing geometry data";
    }

    #! Creates a record (writes a WKT geometry line)
    /** @param rec a hash with a \c geometry key containing a WKT string
        @param create_options not used

        @return the record written

        @throw GEOS-WKT-ERROR if the geometry cannot be parsed as valid WKT
    */
    private *hash<auto> createRecordImpl(hash<auto> rec, *hash<auto> create_options) {
        string wkt = rec.geometry;
        # Validate WKT by parsing it
        parse_wkt(wkt);
        writer.write(wkt + "\n");
        return rec;
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
}
