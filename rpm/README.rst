RPM packaging
=============

Copyright 2026 Qore Technologies, s.r.o.

The canonical qore-geos-module.spec supports Fedora, Enterprise Linux and
openSUSE. It requires the Qore 3.0 SDK and qore-rpm-macros from the same repository.
The default build includes module tests and a separate documentation package.
Dependencies on the installed Qore ABI and SDK version are generated from the
built module; do not replace them with an unversioned qore dependency.

Prepare a pinned source bundle with qore-packaging, then build it in the target
distribution with networking disabled::

    python3 tools/packaging.py prepare --repo ../module-geos --ref COMMIT \
      --name qore-geos-module --version 1.0.0 \
      --spec qore-geos-module.spec --output work/geos-source
    python3 tools/build-local.py --source work/geos-source \
      --image TARGET_SDK_IMAGE --output results/geos-build --jobs 2

These commands run from the qore-packaging repository. Source preparation uses
the committed tree. Install the SDK's language documentation index for complete
Doxygen cross-references. --without docs and --without tests are available for
local diagnosis; repository qualification uses the defaults and also runs the
suite against installed RPMs outside the checkout. Native modules retain the
distribution's normal ELF stripping and separate debug packages.

The package includes native and AOT modules, source fallbacks and separate debug
information. RPM post-processing preserves the AOT dependency trailers.

Documentation builds require the ``qore-devel(module-doc-peers) = 1`` SDK
capability, which resolves sibling-module references before final rendering.
GEOSDataProvider keeps full DWARF, source and AOT metadata, but omits LLVM's
optional name index because distribution GDB does not support it. Initial
debugger loading can be slower. Package checks verify the separate debug link
and retained dependency metadata; qualification verifies source lookup and
breakpoints. Native GEOS module debug processing is unchanged.
