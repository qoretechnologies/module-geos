cmake_minimum_required(VERSION 3.21)

project(qore-geos-module)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Set this before loading Qore's macros so qdx and qjar use the same paths.
# Preserve caller-supplied standard-library paths for QORE_MODULE_DIR_ONLY builds.
set(QORE_MODULE_DIR_FOR_DOCS "${CMAKE_BINARY_DIR}:${CMAKE_BINARY_DIR}/qlib-qmod:${CMAKE_SOURCE_DIR}/qlib")
if(DEFINED ENV{QORE_MODULE_DIR} AND NOT "$ENV{QORE_MODULE_DIR}" STREQUAL "")
    string(APPEND QORE_MODULE_DIR_FOR_DOCS ":$ENV{QORE_MODULE_DIR}")
endif()

find_package(Qore 0.9 REQUIRED)
find_package(GEOS REQUIRED)

include_directories(${CMAKE_SOURCE_DIR}/src)
include_directories(${GEOS_INCLUDE_DIR})

set(QPP_SRC
    src/ql_geos.qpp
    src/QC_GEOSGeometry.qpp
    src/QC_GEOSPreparedGeometry.qpp
    src/QC_GEOSSTRtree.qpp
    src/QC_GEOSWKTReader.qpp
    src/QC_GEOSWKTWriter.qpp
    src/QC_GEOSWKBReader.qpp
    src/QC_GEOSWKBWriter.qpp
    src/QC_GEOSGeoJSONReader.qpp
    src/QC_GEOSGeoJSONWriter.qpp
)

set(CPP_SRC
    src/geos-module.cpp
)

set(QMOD
    qlib/GEOSDataProvider
)

# Check for C++17.
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++17" COMPILER_SUPPORTS_CXX17)
if(COMPILER_SUPPORTS_CXX17)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
else()
    message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++17 support. Please use a different C++ compiler.")
endif()

# enforce reentrant-only GEOS C API
add_definitions(-DGEOS_USE_ONLY_R_API)

qore_wrap_qpp_value(QPP_SOURCES METALIST QPP_META_SOURCES ${QPP_SRC})

SET(module_name "geos")

set(QORE_DOX_TMPL_SRC
    docs/mainpage.doxygen.tmpl
    docs/guide-geosbuilding.dox.tmpl
    docs/guide-geosclasses.dox.tmpl
    docs/guide-geosconstants.dox.tmpl
    docs/guide-geosexamples.dox.tmpl
    docs/guide-geosfunctions.dox.tmpl
    docs/guide-geosreleasenotes.dox.tmpl
    docs/guide-geostypes.dox.tmpl
)

add_library(${module_name} MODULE ${CPP_SRC} ${QPP_SOURCES})

if(WIN32 AND MINGW AND MSYS)
    target_compile_definitions(${module_name} PUBLIC BUILDING_DLL)
endif()

if(DEFINED ENV{DOXYGEN_EXECUTABLE})
    set(DOXYGEN_EXECUTABLE $ENV{DOXYGEN_EXECUTABLE})
endif()

set(QORE_DOXYGEN_IMAGES
    "${CMAKE_SOURCE_DIR}/qlib/GEOSDataProvider/geos-logo.svg"
)
qore_external_binary_module(${module_name} "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}" ${GEOS_LIBRARY})

# install qpp metadata files
if(COMMAND qore_install_qpp_metadata)
    qore_install_qpp_metadata(${module_name} ${QPP_META_SOURCES})
else()
    install(FILES ${QPP_META_SOURCES}
            DESTINATION ${CMAKE_INSTALL_DATADIR}/qore/metadata)
endif()

qore_user_modules("${QMOD}")

qore_external_user_module("qlib/GEOSDataProvider" "")

# Reconcile the installed i18n catalog root against the fragments these modules
# currently own.  Installing catalogs is otherwise additive: a fragment installed by
# an earlier generation of these sources survives every later install, is still
# discovered, and makes catalog composition fail as soon as the current generation
# describes the same app differently.
#
# This must come after every call above that installs catalogs, both because those
# calls record the fragment set and because install() rules run in declaration order,
# which is what publishes the manifest after the fragments it describes.  Removals are
# scoped to this project, so fragments Qore and other products install into the same
# shared catalog root are untouched.  Guarded because the helper arrived in Qore 2.3.
if (COMMAND qore_finalize_catalog_install)
    qore_finalize_catalog_install()
endif()

qore_dist("${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

qore_config_info()

if(DOXYGEN_FOUND)
    qore_wrap_dox(QORE_DOX_SRC ${QORE_DOX_TMPL_SRC})
    add_custom_target(QORE_MOD_DOX_FILES DEPENDS ${QORE_DOX_SRC})
    add_dependencies(docs-module QORE_MOD_DOX_FILES)

    qore_binary_module_two_phase_docs(${module_name} "GEOSDataProvider")
endif()
