//! Qore namespace
namespace Qore {
//! GEOS namespace
namespace GEOS {
//! WKT (Well-Known Text) reader for parsing geometry strings
/** @par Example:
    @code{.py}
GEOSWKTReader reader();
GEOSGeometry geom = reader.read("POINT (1.0 2.0)");
    @endcode

    @since geos 1.0
*/
class GEOSWKTReader {

public:
//! Creates a new WKT reader
/***/
 constructor();

public:
//! Reads a WKT string and returns a GEOSGeometry object
/** @param wkt the Well-Known Text string to parse
    @return a new GEOSGeometry object

    @throw GEOS-ERROR error parsing WKT string
*/
GEOSGeometry read(string wkt);
};
}
}
