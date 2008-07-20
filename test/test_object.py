# -*- coding: utf-8 -*-
import unittest

import jscore

class TestComparison(unittest.TestCase):
    def test_equality(self):
        jscore._object_test_equality()


class TestAttributes(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_missing_attribute(self):
        script = '''o = Object;'''
        out = self.ctx.evaluate_script(script)
        self.assert_(isinstance(out, jscore.JSObject))
        self.assertRaises(AttributeError, getattr, out, 'non_existing')

    def _generic_attribute_test(self, value, python_value):
        script = u'''
o = Object();
o.foo = %s;
o;
''' % value
        out = self.ctx.evaluate_script(script)
        self.assert_(isinstance(out, jscore.JSObject))
        attr = getattr(out, 'foo')
        self.assert_(attr == python_value)

    def test_boolean_attribute(self):
        self._generic_attribute_test('true', True)

    def test_number_attribute(self):
        self._generic_attribute_test('1', 1.0)
        self._generic_attribute_test('1.2345', 1.2345)

    def test_string_attribute(self):
        u = u'abc123&é"(§è!çà)ض'
        self._generic_attribute_test(u'\'%s\'' % u, u)

    def test_null_attribute(self):
        self._generic_attribute_test('null', None)

    def test_undefined_attribute(self):
        script = '''
o = Object();
o.foo = undefined;
o;
'''
        out = self.ctx.evaluate_script(script)
        self.assert_(isinstance(out, jscore.JSObject))
        self.assertRaises(AttributeError, getattr, out, 'foo')

    def test_multilevel_attribute(self):
        script = '''
o = Object();
o.foo = Object();
o.foo.bar = Object();
o.foo.bar.baz = 1;
o;
'''
        out = self.ctx.evaluate_script(script)
        self.assert_(isinstance(out, jscore.JSObject))
        value = out.foo.bar.baz
        self.assert_(value == 1)
