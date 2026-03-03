/* -*- mode: c++; indent-tabs-mode: nil -*- */
/*
    QC_GEOSSTRtree.h

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

#ifndef _QORE_QC_GEOSSTRTREE_H
#define _QORE_QC_GEOSSTRTREE_H

#include "geos-module.h"
#include "QC_GEOSGeometry.h"

#include <vector>

struct TreeEntry {
    QoreObject* geomObj;   // strong ref to geometry QoreObject
    QoreValue item;        // user data associated with the geometry

    TreeEntry(QoreObject* go, QoreValue it) : geomObj(go), item(it) {
        geomObj->ref();
        item.refSelf();
    }

    ~TreeEntry() {
        geomObj->deref(nullptr);
        item.discard(nullptr);
    }
};

// Query callback context
struct QueryCallbackContext {
    ReferenceHolder<QoreListNode>* result;
    ExceptionSink* xsink;
    int count;
};

class QoreGEOSSTRtree : public AbstractPrivateData {
public:
    DLLLOCAL QoreGEOSSTRtree(int nodeCapacity = 10) {
        GEOSContextHandle_t ctx = geos_get_context();
        tree = GEOSSTRtree_create_r(ctx, nodeCapacity);
    }

    DLLLOCAL virtual ~QoreGEOSSTRtree() {
        if (tree) {
            GEOSSTRtree_destroy_r(geos_get_context(), tree);
        }
        // entries are cleaned up by vector destructor calling TreeEntry destructors
        for (auto& entry : entries) {
            delete entry;
        }
    }

    DLLLOCAL GEOSSTRtree* getTree() const {
        return tree;
    }

    DLLLOCAL void insert(QoreObject* geomObj, QoreGEOSGeometry* geom, QoreValue item) {
        TreeEntry* entry = new TreeEntry(geomObj, item);
        entries.push_back(entry);
        GEOSSTRtree_insert_r(geos_get_context(), tree, geom->getGeometry(), entry);
    }

    DLLLOCAL size_t size() const {
        return entries.size();
    }

    DLLLOCAL std::vector<TreeEntry*>& getEntries() {
        return entries;
    }

private:
    GEOSSTRtree* tree = nullptr;
    std::vector<TreeEntry*> entries;
};

#endif
