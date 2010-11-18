#!/usr/bin/env python
# encoding: utf-8
"""
develop.py

Created by Kurtiss Hare on 2010-11-18.
Copyright (c) 2010 Medium Entertainment, Inc. All rights reserved.
"""

import pkg_resources

__version__ = pkg_resources.resource_string(__name__, 'develop_data/VERSION')


def initialize_source(args):
    return pkg_resources.resource_string(__name__, 'develop_data/develop.sh')