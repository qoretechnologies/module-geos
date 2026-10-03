#!/usr/bin/env python3
# Copyright (C) 2026 Qore Technologies, s.r.o.
# SPDX-License-Identifier: MIT
"""Check generated GEOS symbol links: python3 test/test_docs.py build -v."""

from html.parser import HTMLParser
from pathlib import Path
import sys
import unittest
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET


BUILD = Path(sys.argv.pop(1)).resolve()
HTML = BUILD / 'docs/geos/html'


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.ids = set()
        self.links = []
        self.text = []
        self.current = None
        self.feed(path.read_text())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'a' and 'href' in attrs:
            self.current = [attrs['href'], '']

    def handle_data(self, data):
        self.text.append(data)
        if self.current is not None:
            self.current[1] += data

    def handle_endtag(self, tag):
        if tag == 'a' and self.current is not None:
            self.links.append(tuple(self.current))
            self.current = None


class DocsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tags = ET.parse(BUILD / 'geos.tag')
        cls.index = Page(HTML / 'index.html')

    def compound_target(self, name):
        targets = [compound.findtext('filename') for compound in self.tags.findall('compound')
                   if compound.findtext('name') == name]
        self.assertEqual(1, len(targets), name)
        return targets[0]

    def test_intro_class_names_link_to_their_api(self):
        for name in ('GEOSGeometry', 'GEOSPreparedGeometry', 'GEOSSTRtree'):
            with self.subTest(name=name):
                self.assertIn((self.compound_target('Qore::GEOS::' + name), name), self.index.links)
        self.assertIn(('geosclassesguide.html', 'WKT/WKB/GeoJSON reader/writer classes'), self.index.links)

    def test_every_provider_module_link_uses_its_intro(self):
        links = [href for href, label in self.index.links if label == 'GEOSDataProvider']
        self.assertEqual(3, len(links))
        self.assertEqual({'../../GEOSDataProvider/html/index.html#geosdataproviderintro'}, set(links))

    def test_constant_examples_link_to_member_definitions(self):
        page = Page(HTML / 'geosconstantsguide.html')
        namespace = self.tags.find("compound[name='Qore::GEOS']")
        self.assertIsNotNone(namespace)
        for name in ('GEOS_POINT', 'GEOS_LINESTRING', 'GEOS_POLYGON',
                     'GEOS_MAKE_VALID_LINEWORK', 'GEOS_MAKE_VALID_STRUCTURE',
                     'GEOSBUF_CAP_ROUND', 'GEOSBUF_CAP_FLAT', 'GEOSBUF_JOIN_MITRE'):
            with self.subTest(name=name):
                member = namespace.find(f"member[name='{name}']")
                self.assertIsNotNone(member)
                target = member.findtext('anchorfile') + '#' + member.findtext('anchor')
                self.assertIn((target, name), page.links)

    def test_hash_types_use_the_runtime_namespace(self):
        page = Page(HTML / 'geostypesguide.html')
        for name in ('GEOSCoordinate', 'GEOSExtent', 'GEOSVersionInfo'):
            with self.subTest(name=name):
                target = self.compound_target('Qore::GEOS::' + name)
                self.assertTrue((HTML / target).is_file(), target)
                self.assertIsNone(self.tags.find(f"compound[name='Qore::{name}']"))
                if name != 'GEOSVersionInfo':
                    self.assertIn((target, name), page.links)
                    self.assertIn('hash<' + name + '>', ''.join(page.text))

    def test_all_local_guide_links_and_fragments_exist(self):
        guides = [HTML / 'index.html', *sorted(HTML.glob('geos*guide.html'))]
        self.assertEqual(8, len(guides))
        for path in guides:
            for href, _ in Page(path).links:
                url = urlsplit(href)
                if url.scheme or url.netloc:
                    continue
                with self.subTest(page=path.name, href=href):
                    target = path.parent / unquote(url.path) if url.path else path
                    self.assertTrue(target.is_file(), href)
                    if url.fragment:
                        self.assertIn(unquote(url.fragment), Page(target).ids, href)


if __name__ == '__main__':
    unittest.main()
