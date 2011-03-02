#!/usr/bin/env python
# encoding: utf-8

import unittest2 as unittest
from ${PROJECT}_testsuite.all import cases


def load_tests(loader, tests, pattern):
    suite = unittest.TestSuite()
    for case in cases:
        suite.addTests(loader.loadTestsFromTestCase(case))
    return suite