# - Find GEOS (Geometry Engine - Open Source) C API
# Once done this will define:
#  GEOS_FOUND       - system has GEOS
#  GEOS_INCLUDE_DIR - the GEOS include directory
#  GEOS_LIBRARY     - the GEOS C library
#
# Supported platforms: Ubuntu, Alpine, macOS (Homebrew/MacPorts), Fedora, FreeBSD

# Try geos-config first (most reliable on Unix-like systems)
find_program(GEOS_CONFIG geos-config)
if(GEOS_CONFIG)
    execute_process(COMMAND ${GEOS_CONFIG} --includes
        OUTPUT_VARIABLE GEOS_CONFIG_INCLUDES
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    # strip -I prefix if present
    string(REGEX REPLACE "^-I" "" GEOS_CONFIG_INCLUDES "${GEOS_CONFIG_INCLUDES}")

    execute_process(COMMAND ${GEOS_CONFIG} --clibs
        OUTPUT_VARIABLE GEOS_CONFIG_LIBS
        OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

find_path(GEOS_INCLUDE_DIR geos_c.h
    HINTS
        ${GEOS_CONFIG_INCLUDES}
        ${GEOS_DIR}/include
        $ENV{GEOS_DIR}/include
    PATHS
        /usr/include
        /usr/local/include
        /opt/local/include          # MacPorts
        /opt/homebrew/include       # Homebrew ARM
        /usr/local/opt/geos/include # Homebrew x86
)

find_library(GEOS_LIBRARY
    NAMES geos_c
    HINTS
        ${GEOS_DIR}/lib
        $ENV{GEOS_DIR}/lib
    PATHS
        /usr/lib
        /usr/lib64
        /usr/local/lib
        /usr/local/lib64
        /opt/local/lib              # MacPorts
        /opt/homebrew/lib           # Homebrew ARM
        /usr/local/opt/geos/lib     # Homebrew x86
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GEOS DEFAULT_MSG GEOS_LIBRARY GEOS_INCLUDE_DIR)

mark_as_advanced(GEOS_INCLUDE_DIR GEOS_LIBRARY GEOS_CONFIG)
