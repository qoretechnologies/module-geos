/* -*- mode: c++; indent-tabs-mode: nil -*- */
/*
    geos-module.cpp

    Qore Programming Language

    Copyright (C) 2026 Qore Technologies, s.r.o.

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

#include "geos-module.h"

static void geos_module_init(QoreModuleInitContext& ctx, ExceptionSink& xsink);
static void geos_module_ns_init(QoreNamespace* rns, QoreNamespace* qns, ExceptionSink& xsink);
static void geos_module_delete();

extern "C" DLLEXPORT void geos_qore_module_desc(QoreModuleInfo& mod_info) {
    mod_info.name = "geos";
    mod_info.version = PACKAGE_VERSION;
    mod_info.desc = "GEOS module";
    mod_info.author = "David Nichols";
    mod_info.url = "https://github.com/qoretechnologies/module-geos";
    mod_info.api_major = QORE_MODULE_API_MAJOR;
    mod_info.api_minor = QORE_MODULE_API_MINOR;
    mod_info.init = geos_module_init;
    mod_info.ns_init = geos_module_ns_init;
    mod_info.del = geos_module_delete;
    mod_info.license = QL_MIT;
    mod_info.license_str = "MIT";
}

// Thread-local GEOS error message
thread_local std::string geos_error_msg;

// Thread-local GEOS context handle
static thread_local GEOSContextHandle_t tl_geos_ctx = nullptr;

static void geos_error_handler(const char* message, void* userdata) {
    geos_error_msg = message;
}

static void geos_notice_handler(const char* message, void* userdata) {
    // ignore notices
}

GEOSContextHandle_t geos_get_context() {
    if (!tl_geos_ctx) {
        tl_geos_ctx = GEOS_init_r();
        GEOSContext_setErrorMessageHandler_r(tl_geos_ctx, geos_error_handler, nullptr);
        GEOSContext_setNoticeMessageHandler_r(tl_geos_ctx, geos_notice_handler, nullptr);
    }
    return tl_geos_ctx;
}

bool check_geos_error(ExceptionSink* xsink, const char* err_code, const char* desc) {
    if (!geos_error_msg.empty()) {
        std::string msg = geos_error_msg;
        geos_error_msg.clear();
        xsink->raiseException(err_code, "%s: %s", desc, msg.c_str());
        return true;
    }
    return false;
}

// hashdecl pointers
const TypedHashDecl* hashdeclGEOSCoordinate = nullptr;
const TypedHashDecl* hashdeclGEOSVersionInfo = nullptr;


QoreNamespace GNS("Qore::GEOS");

static void geos_module_init(QoreModuleInitContext& ctx, ExceptionSink& xsink) {
    // add hashdecls first (referenced by classes and functions)
    hashdeclGEOSCoordinate = init_hashdecl_GEOSCoordinate(GNS);
    hashdeclGEOSVersionInfo = init_hashdecl_GEOSVersionInfo(GNS);
    // add GEOSGeometry first (referenced by all other classes and functions)
    QC_GEOSGEOMETRY = initGEOSGeometryClass(GNS);
    GNS.addSystemClass(QC_GEOSGEOMETRY);
    // add remaining classes (depend on GEOSGeometry)
    QC_GEOSPREPAREDGEOMETRY = initGEOSPreparedGeometryClass(GNS);
    GNS.addSystemClass(QC_GEOSPREPAREDGEOMETRY);
    QC_GEOSSTRTREE = initGEOSSTRtreeClass(GNS);
    GNS.addSystemClass(QC_GEOSSTRTREE);
    QC_GEOSWKTREADER = initGEOSWKTReaderClass(GNS);
    GNS.addSystemClass(QC_GEOSWKTREADER);
    QC_GEOSWKTWRITER = initGEOSWKTWriterClass(GNS);
    GNS.addSystemClass(QC_GEOSWKTWRITER);
    QC_GEOSWKBREADER = initGEOSWKBReaderClass(GNS);
    GNS.addSystemClass(QC_GEOSWKBREADER);
    QC_GEOSWKBWRITER = initGEOSWKBWriterClass(GNS);
    GNS.addSystemClass(QC_GEOSWKBWRITER);
    // add functions last (reference both hashdecls and classes)
    init_geos_functions(GNS);
}

static void geos_module_ns_init(QoreNamespace* rns, QoreNamespace* qns, ExceptionSink& xsink) {
    qns->addNamespace(GNS.copy());
}

static void geos_module_delete() {
}
