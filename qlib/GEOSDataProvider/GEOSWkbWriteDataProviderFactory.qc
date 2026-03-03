# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore GEOSWkbWriteDataProviderFactory class definition

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
#! Factory class for GEOS WKB write data providers
public class GEOSWkbWriteDataProviderFactory inherits DataProvider::AbstractDataProviderFactory {
    public {
        #! Factory info
        const FactoryInfo = <DataProviderFactoryInfo>{
            "name": "geoswkbwrite",
            "desc": "Data provider factory for writing WKB (Well-Known Binary) geometry data",
        };
    }

    #! Returns the factory info
    hash<DataProviderFactoryInfo> getInfoImpl() {
        return FactoryInfo;
    }

    #! Returns the class for the data provider
    Class getClassImpl() {
        return Class::forName("GEOSDataProvider::GEOSWkbWriteDataProvider");
    }

    #! Returns the data provider from the given options
    private DataProvider::AbstractDataProvider createImpl(hash<auto> options, *LoggerInterface logger) {
        return new GEOSWkbWriteDataProvider(options);
    }

    #! Returns static provider information as data; no connection is required
    *hash<auto> getInfoAsDataImpl(hash<auto> constructor_options, *bool with_type_info) {
        return GEOSWkbWriteDataProvider::ProviderInfo;
    }

    #! Returns the description of the factory
    string getDescImpl() {
        return FactoryInfo.desc;
    }

    #! Returns provider info
    private hash<DataProvider::DataProviderInfo> getProviderInfoImpl() {
        return GEOSWkbWriteDataProvider::ProviderInfo;
    }
}
}
