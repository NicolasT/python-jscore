import unittest

import jscore

class TestGlobalContext(unittest.TestCase):
    def test_instanciation(self):
        ctx = jscore.GlobalContext()

class TestContext(unittest.TestCase):
    def setUp(self):
        self.ctx = jscore.GlobalContext()

    def test_get_global_object(self):
        g = self.ctx.get_global_object()

        self.assert_(g)
        self.assert_(isinstance(g, jscore.JSObject))

    def test_check_script_syntax_valid(self):
        script = 'a = 1; b = 2; c = a + b;'
        result = self.ctx.check_script_syntax(script)

        self.assert_(result is True)

    def test_check_script_syntax_invalid(self):
        script = '--- I am an invalid script ---'
        result = self.ctx.check_script_syntax(script)

        self.assert_(result is False)

    def test_check_script_syntax_params(self):
        script = 'a_valid_script;'

        result = self.ctx.check_script_syntax(script,
                'http://eikke.com/test.js')
        self.assert_(result is True)
        
        result = self.ctx.check_script_syntax(script,
                'http://eikke.com/test.js', 123)
        self.assert_(result is True)

    def test_check_script_syntax_empty_script(self):
        script = None
        self.assertRaises(ValueError, self.ctx.check_script_syntax, script)

        script = ''
        self.assertRaises(ValueError, self.ctx.check_script_syntax, script)

    def test_garbage_collect(self):
        self.ctx.garbage_collect()

    def test_evaluate_script_valid(self):
        script = 'a = 1; b = 2; c = 1 + 2;'
        res = self.ctx.evaluate_script(script)

    def test_evaluate_script_invalid(self):
        script = 'a -;'
        self.assertRaises(RuntimeError, self.ctx.evaluate_script, script)

    def test_evaluate_script_empty(self):
        script = ''
        self.assertRaises(ValueError, self.ctx.evaluate_script, script)

    def test_evaluatate_script_type_number(self):
        script = 'a = 1.234;'
        self.assertEquals(self.ctx.evaluate_script(script), 1.234)

    def test_evaluate_script_type_bool(self):
        script = 'a = true;'
        self.assertEquals(self.ctx.evaluate_script(script), True)

    def test_evaluate_script_type_string(self):
        u = u'abc123&é"(§è!çà)ض'
        script = u'a = \'%s\';' % u
        self.assertEquals(self.ctx.evaluate_script(script), u)

    def test_evaluate_script_type_string_utf8(self):
        u1 = u'abc123&é"(§è!çà)ض'
        u2 = u'ธฒฟໂໜ'
        expected = u'%sabc%s' % (u1, u2)
        script = u'a = \'%s\' + \'abc\' + \'%s\';' % (u1, u2)
        self.assertEquals(self.ctx.evaluate_script(script), expected)

    def test_evaluate_script_type_null(self):
        script = 'a = null;'
        self.assertEquals(self.ctx.evaluate_script(script), None)

    def test_evaluate_script_type_object(self):
        script = 'o = Object();'
        res = self.ctx.evaluate_script(script)
        self.assert_(isinstance(res, jscore.JSObject))
