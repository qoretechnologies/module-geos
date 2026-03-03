/* -*- mode: c++; indent-tabs-mode: nil -*- */
/*
    geos-module.h

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

#ifndef _QORE_GEOS_MODULE_H
#define _QORE_GEOS_MODULE_H

#ifdef HAVE_CONFIG_H
#include "../config.h"
#endif

#include <qore/Qore.h>

#include <geos_c.h>

#include <string>

// Thread-local GEOS context management
// Each thread gets its own GEOS context handle for thread safety.
// Error messages from GEOS are captured in a thread-local string.

// Thread-local error string set by the GEOS error callback
DLLLOCAL extern thread_local std::string geos_error_msg;

// Get or lazily initialize the thread-local GEOS context handle
DLLLOCAL GEOSContextHandle_t geos_get_context();

// Check if GEOS reported an error and raise a Qore exception if so.
// Returns true if an error was raised (caller should return).
DLLLOCAL bool check_geos_error(ExceptionSink* xsink, const char* err_code, const char* desc);

// check_geos_error helper only

// hashdecl pointers
DLLLOCAL extern const TypedHashDecl* hashdeclGEOSCoordinate;
DLLLOCAL extern const TypedHashDecl* hashdeclGEOSVersionInfo;

// class pointers
DLLLOCAL extern QoreClass* QC_GEOSGEOMETRY;
DLLLOCAL extern QoreClass* QC_GEOSPREPAREDGEOMETRY;
DLLLOCAL extern QoreClass* QC_GEOSSTRTREE;
DLLLOCAL extern QoreClass* QC_GEOSWKTREADER;
DLLLOCAL extern QoreClass* QC_GEOSWKTWRITER;
DLLLOCAL extern QoreClass* QC_GEOSWKBREADER;
DLLLOCAL extern QoreClass* QC_GEOSWKBWRITER;

// class IDs
DLLLOCAL extern qore_classid_t CID_GEOSGEOMETRY;
DLLLOCAL extern qore_classid_t CID_GEOSPREPAREDGEOMETRY;
DLLLOCAL extern qore_classid_t CID_GEOSSTRTREE;
DLLLOCAL extern qore_classid_t CID_GEOSWKTREADER;
DLLLOCAL extern qore_classid_t CID_GEOSWKTWRITER;
DLLLOCAL extern qore_classid_t CID_GEOSWKBREADER;
DLLLOCAL extern qore_classid_t CID_GEOSWKBWRITER;

// QPP-generated init functions
DLLLOCAL void init_geos_functions(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_GEOSCoordinate(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_GEOSVersionInfo(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSGeometryClass(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSPreparedGeometryClass(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSSTRtreeClass(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSWKTReaderClass(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSWKTWriterClass(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSWKBReaderClass(QoreNamespace& ns);
DLLLOCAL QoreClass* initGEOSWKBWriterClass(QoreNamespace& ns);

#endif
