# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSGeoJsonWriteDataProvider class definition

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
#! Data provider for writing GeoJSON geometry data
/** This data provider allows writing GeoJSON geometry data to files or streams
    using the DataProvider API. Each geometry is written as a single compact GeoJSON line.

    Output can be directed to:
    - \c path: a filesystem path or location URL (processed by FileLocationHandler)
    - \c stream: an OutputStream object

    Each record must contain:
    - \c geometry (string): a valid GeoJSON geometry string, or a WKT string (which will be
      converted to GeoJSON)

    @par Example: Write to a file
    @code{.py}
    GEOSGeoJsonWriteDataProvider provider({"path": "output.geojson"});
    provider.createRecord({"geometry": '{"type":"Point","coordinates":[1,2]}'});
    @endcode

    @since geos 1.1
*/
public class GEOSGeoJsonWriteDataProvider inherits DataProvider::AbstractDataProvider {
    public {
        #! Provider info
        const ProviderInfo = <DataProviderInfo>{
            "name": "geosgeojsonwrite",
            "desc": "GEOS GeoJSON data provider for writing GeoJSON geometry data",
            "type": "GEOSGeoJsonWriteDataProvider",
            "supports_create": True,
            "supports_request": False,
            "has_record": True,
            "constructor_options": ConstructorOptions,
        };

        #! Constructor options
        const ConstructorOptions = {
            "path": <DataProviderOptionInfo>{
                "display_name": "Output Path",
                "short_desc": "The path to the output GeoJSON file",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The filesystem path or location URL for the GeoJSON output file; the output "
                    "location is handled by a call to "
                    "[FileLocationHandler::getOutputStreamForLocation()]()",
            },
            "stream": <DataProviderOptionInfo>{
                "display_name": "Output Stream",
                "short_desc": "The output stream to write to",
                "type": AbstractDataProviderTypeMap."any",
                "desc": "An output stream to write GeoJSON data to",
            },
            "encoding": <DataProviderOptionInfo>{
                "display_name": "Encoding",
                "short_desc": "Character encoding for the output",
                "type": AbstractDataProviderTypeMap."string",
                "desc": "The character encoding to use when writing the output (default: UTF-8)",
                "default_value": DefaultEncoding,
            },
        };

        #! Record type for GeoJSON write records
        const RecordType = new HashDataType("GEOSGeoJsonWriteRecord", {
            "geometry": {
                "display_name": "Geometry",
                "short_desc": "The geometry as GeoJSON or WKT",
                "desc": "The geometry to write; can be a GeoJSON string or a WKT string "
                    "(WKT strings are automatically converted to GeoJSON)",
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

        @throw GEOS-GEOJSON-ERROR if no output target is provided
    */
    constructor(*hash<auto> options) {
        Qore::OutputStream os;
        string encoding = options.encoding ?? DefaultEncoding;
        if (exists options.path) {
            os = FileLocationHandler::getOutputStreamForLocation(options.path);
        } else if (exists options.stream) {
            os = options.stream;
        } else {
            throw "GEOS-GEOJSON-ERROR", "one of 'path' or 'stream' must be provided";
        }
        writer = new StreamWriter(os, encoding);
    }

    #! Returns the data provider name
    string getName() {
        return "geosgeojsonwrite";
    }

    #! Returns the data provider description
    *string getDesc() {
        return "GEOS GeoJSON data provider for writing geometry data";
    }

    #! Creates a record (writes a GeoJSON geometry line)
    /** @param rec a hash with a \c geometry key containing a GeoJSON or WKT string
        @param create_options not used

        @return the record written

        @throw GEOS-GEOJSON-ERROR if the geometry cannot be parsed
    */
    private *hash<auto> createRecordImpl(hash<auto> rec, *hash<auto> create_options) {
        string input = rec.geometry;
        string geojson;
        # try to parse as GeoJSON first; if that fails, try WKT and convert
        try {
            GEOSGeometry geom = parse_geojson(input);
            geojson = input;
        } catch (hash<ExceptionInfo> ex) {
            # try WKT
            GEOSGeometry geom = parse_wkt(input);
            geojson = make_geojson(geom);
        }
        writer.write(geojson + "\n");
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
