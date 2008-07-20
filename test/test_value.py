import unittest

import jscore

class TestBoolean(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_instanciate_true(self):
        b = jscore.BooleanValue(self.ctx, True)

    def test_instanciate_false(self):
        b = jscore.BooleanValue(self.ctx, False)

    def test_instanciate_invalid_context(self):
        self.assertRaises(ValueError, jscore.BooleanValue, None, True)
        self.assertRaises(TypeError, jscore.BooleanValue, 123, False)

    def test_instanciate_invalid_value(self):
        self.assertRaises(ValueError, jscore.BooleanValue, self.ctx, 123)

    def test_true(self):
        b = jscore.BooleanValue(self.ctx, True)
        self.assertEquals(b.python_value(self.ctx), True)

    def test_false(self):
        b = jscore.BooleanValue(self.ctx, False)
        self.assertEquals(b.python_value(self.ctx), False)


class TestNumber(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_instanciate_int(self):
        n = jscore.NumberValue(self.ctx, 123)

    def test_instanciate_float(self):
        n = jscore.NumberValue(self.ctx, 3.14159265)

    def test_instanciate_long(self):
        n = jscore.NumberValue(self.ctx, 123456789L)

    def test_instanciate_invalid_context(self):
        self.assertRaises(ValueError, jscore.NumberValue, None, 1.0)
        self.assertRaises(TypeError, jscore.NumberValue, 123, 1234)

    def test_instanciate_invalid_value(self):
        self.assertRaises(ValueError, jscore.NumberValue, self.ctx, 'testing')

    def test_int(self):
        i = 123
        n = jscore.NumberValue(self.ctx, i)
        self.assertEquals(n.python_value(self.ctx), i)

    def test_float(self):
        i = 3.14159265
        n = jscore.NumberValue(self.ctx, i)
        self.assertEquals(n.python_value(self.ctx), i)

    def test_long(self):
        i = 1234567890L
        n = jscore.NumberValue(self.ctx, i)
        self.assertEquals(n.python_value(self.ctx), i)


class TestString(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_instanciate_str(self):
        s = jscore.StringValue(self.ctx, 'abc')

    def test_instanciate_String(self):
        s = jscore.StringValue(self.ctx, jscore.String('abc123'))

    def test_instanciate_invalid_context(self):
        self.assertRaises(ValueError, jscore.StringValue, None, 'abc')
        self.assertRaises(TypeError, jscore.StringValue, 123, 'abc')

    def test_instanciate_invalid_value(self):
        self.assertRaises(TypeError, jscore.StringValue, self.ctx, 123)

    def test_value(self):
        i = u'abc123'
        s = jscore.StringValue(self.ctx, i)
        self.assertEquals(s.python_value(self.ctx), i)
        self.assertEquals(unicode(s.python_value(self.ctx)), i)


class TestNull(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_instanciate(self):
        s = jscore.NullValue(self.ctx, None)

    def test_instanciate_invalid_context(self):
        self.assertRaises(ValueError, jscore.StringValue, None, None)
        self.assertRaises(TypeError, jscore.StringValue, 123, None)

    def test_instanciate_invalid_value(self):
        self.assertRaises(TypeError, jscore.StringValue, self.ctx, 123)

    def test_value(self):
        i = None
        n = jscore.NullValue(self.ctx, i)
        self.assertEquals(n.python_value(self.ctx), i)


class TestUndefined(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_instanciate(self):
        s = jscore.UndefinedValue(self.ctx, jscore.UNDEFINED)

    def test_instanciate_invalid_context(self):
        self.assertRaises(ValueError, jscore.UndefinedValue, None,
                jscore.UNDEFINED)
        self.assertRaises(TypeError, jscore.UndefinedValue, 123,
                jscore.UNDEFINED)

    def test_instanciate_invalid_value(self):
        self.assertRaises(TypeError, jscore.StringValue, self.ctx, 123)

    def test_value(self):
        i = jscore.UNDEFINED
        n = jscore.UndefinedValue(self.ctx, i)
        self.assertEquals(n.python_value(self.ctx), i)


class TestValue(unittest.TestCase):
    def test_bool(self):
        jscore._value_test_bool()

    def test_number(self):
        jscore._value_test_number()

    def test_string(self):
        jscore._value_test_string()

    def test_null(self):
        jscore._value_test_null()

    def test_undefined(self):
        jscore._value_test_undefined()

    def test_object(self):
        jscore._value_test_object()
