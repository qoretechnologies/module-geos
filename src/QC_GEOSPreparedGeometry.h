/* -*- mode: c++; indent-tabs-mode: nil -*- */
/*
    QC_GEOSPreparedGeometry.h

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

#ifndef _QORE_QC_GEOSPREPAREDGEOMETRY_H
#define _QORE_QC_GEOSPREPAREDGEOMETRY_H

#include "geos-module.h"

class QoreGEOSPreparedGeometry : public AbstractPrivateData {
public:
    // pg: the prepared geometry pointer (owned by GEOS, tied to source geometry lifetime)
    // source_obj: the QoreObject for the source GEOSGeometry (strong ref to prevent GC)
    DLLLOCAL QoreGEOSPreparedGeometry(const GEOSPreparedGeometry* pg, QoreObject* source_obj)
        : prep(pg), sourceObj(source_obj) {
    }

    DLLLOCAL virtual ~QoreGEOSPreparedGeometry() {
        if (prep) {
            GEOSPreparedGeom_destroy_r(geos_get_context(), prep);
        }
        if (sourceObj) {
            sourceObj->deref(nullptr);
        }
    }

    DLLLOCAL const GEOSPreparedGeometry* getPreparedGeometry() const {
        return prep;
    }

private:
    const GEOSPreparedGeometry* prep;
    QoreObject* sourceObj;
};

#endif
