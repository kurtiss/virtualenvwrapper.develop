#!/usr/bin/env python
# encoding: utf-8
"""
develop.py

Created by Kurtiss Hare on 2010-08-09.
Copyright (c) 2010 Medium Entertainment, Inc. All rights reserved.
"""

import pkg_resources


def initialize_source(args):
    return pkg_resources.resource_string(__name__, 'develop.sh')