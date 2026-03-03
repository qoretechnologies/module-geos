cmake_minimum_required(VERSION 3.5)

project(qore-geos-module)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(Qore 0.9 REQUIRED)
find_package(GEOS REQUIRED)

# ensure qdx can find the geos binary module and user modules when processing .qc files
set(QORE_MODULE_DIR_FOR_DOCS "${CMAKE_BINARY_DIR}:${CMAKE_SOURCE_DIR}/qlib")

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
)

set(CPP_SRC
    src/geos-module.cpp
)

set(QMOD
    qlib/GEOSDataProvider
)

# Check for C++11.
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
if(COMPILER_SUPPORTS_CXX11)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
else()
    message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif()

# enforce reentrant-only GEOS C API
add_definitions(-DGEOS_USE_ONLY_R_API)

qore_wrap_qpp_value(QPP_SOURCES METALIST QPP_META_SOURCES ${QPP_SRC})

SET(module_name "geos")

set(QORE_DOX_TMPL_SRC
    docs/mainpage.doxygen.tmpl
)

add_library(${module_name} MODULE ${CPP_SRC} ${QPP_SOURCES})

if(WIN32 AND MINGW AND MSYS)
    target_compile_definitions(${module_name} PUBLIC BUILDING_DLL)
endif()

if(DEFINED ENV{DOXYGEN_EXECUTABLE})
    set(DOXYGEN_EXECUTABLE $ENV{DOXYGEN_EXECUTABLE})
endif()

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

qore_dist("${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

qore_config_info()

if(DOXYGEN_FOUND)
    qore_wrap_dox(QORE_DOX_SRC ${QORE_DOX_TMPL_SRC})
    add_custom_target(QORE_MOD_DOX_FILES DEPENDS ${QORE_DOX_SRC})
    add_dependencies(docs-module QORE_MOD_DOX_FILES)

    # Two-phase doc build: the initial pass (docs-module) generates geos.tag with empty
    # TAGFILES. User module docs (docs-GEOSDataProvider) are then built using geos.tag,
    # generating their own tag file. The final pass (docs-module-final) rebuilds the binary
    # module docs with user module tag files in TAGFILES, enabling @ref cross-references
    # from the mainpage into user module symbols.

    # Suppress unresolved cross-reference warnings in the initial pass
    file(APPEND ${CMAKE_BINARY_DIR}/Doxyfile "\n# Suppress warnings for initial pass (no user module TAGFILES available)\nWARN_IF_DOC_ERROR = NO\n")

    # Create final-pass Doxyfile from the binary module's Doxyfile with user module tag files
    # (copy + append, NOT configure_file with user module template which has wrong INPUT)
    file(COPY_FILE ${CMAKE_BINARY_DIR}/Doxyfile ${CMAKE_BINARY_DIR}/Doxyfile.final)
    file(APPEND ${CMAKE_BINARY_DIR}/Doxyfile.final
        "\n# Final pass: enable user module cross-references and re-enable doc error warnings\nTAGFILES = ${CMAKE_BINARY_DIR}/GEOSDataProvider.tag=../../GEOSDataProvider/html\nWARN_IF_DOC_ERROR = YES\n")

    add_custom_target(docs-module-final
        COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_BINARY_DIR}/Doxyfile.final
        COMMAND ${QORE_DOCS_ENV} ${QORE_QDX_COMMAND} --post ${CMAKE_BINARY_DIR}/docs/${module_name}/html ${CMAKE_BINARY_DIR}/docs/${module_name}/html/search
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating API documentation with Doxygen (final pass with user module cross-references)"
        VERBATIM
    )
    add_dependencies(docs-module-final docs-GEOSDataProvider)
    add_dependencies(docs docs-module-final)
endif()
