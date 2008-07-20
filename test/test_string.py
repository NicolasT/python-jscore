# -*- coding: utf-8 -*-
import unittest

from jscore import String

class TestCreation(unittest.TestCase):
    def test_empty(self):
        s = String('')

    def test_none(self):
        s = String(None)

    def test_utf8(self):
        s = String(u'abc123&é"(§è!çà)ض')


class TestStr(unittest.TestCase):
    def test_empty(self):
        i = ''
        s = String(i)
        u = str(s)
        self.assertEqual(i, u)

    def test_none(self):
        s = String(None)
        self.assertRaises(ValueError, str, s)

    def test_utf8(self):
        i = u'abc123&é"(§è!çà)ض'
        s = String(i)
        self.assertRaises(UnicodeEncodeError, str, s)


class TestUnicode(unittest.TestCase):
    def test_empty(self):
        i = u''
        s = String(i)
        u = unicode(s)
        self.assertEqual(i, u)

    def test_none(self):
        s = String(None)
        self.assertRaises(ValueError, unicode, s)

    def test_utf8(self):
        i = u'abc123&é"(§è!çà)ض'
        s = String(i)
        u = unicode(s)
        self.assertEqual(i, u)

    def test_very_long_utf8(self):
        i = u'abc123&é"(§è!çà)ض' * 1000
        s = String(i)
        u = unicode(s)
        self.assertEqual(i, u)


class TestEquality_str(unittest.TestCase):
    def test_empty(self):
        i = ''
        s = String(i)
        self.assertEqual(s, i)

    def test_none(self):
        i = None
        s = String(i)
        self.assertRaises(TypeError, cmp, s, i)

    def test_ascii(self):
        i = 'abc123'
        s = String(i)
        self.assertEqual(s, i)

    def test_utf8(self):
        i = u'abc123&é"(§è!çà)ض'
        s = String(i)
        self.assertEqual(s, i)


class TestEquality_String(unittest.TestCase):
    def test_empty(self):
        i = ''
        s1 = String(i)
        s2 = String(i)
        self.assertEqual(s1, s2)

    def test_ascii(self):
        i = 'abc123'
        s1 = String(i)
        s2 = String(i)
        self.assertEqual(s1, s2)

    def test_utf8(self):
        i = u'abc123&é"(§è!çà)ض'
        s1 = String(i)
        s2 = String(i)
        self.assertEqual(s1, s2)
