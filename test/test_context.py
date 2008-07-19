import unittest

import jscore

class TestJSContext(unittest.TestCase):
    def test_instanciation(self):
        ctx = jscore.JSGlobalContext()
