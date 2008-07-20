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
        self.assert_(isinstance(g, jscore.Object))

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
