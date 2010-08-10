#!/usr/bin/env python
# encoding: utf-8
"""
setup.py

Created by Kurtiss Hare on 2010-08-09.
Copyright (c) 2010 Medium Entertainment, Inc. All rights reserved.
"""

import distribute_setup
distribute_setup.use_setuptools()

from setuptools import setup, find_packages
import os

setup(
    name = 'virtualenvwrapper.develop',
    version = '0.1',
    description = 'Developer extensions to virtualenvwrapper.',
    author = 'Kurtiss Hare',
    author_email = 'kurtiss@gmail.com',
    url = 'http://www.github.com/kurtiss/virtualenvwrapper.develop',
    packages = find_packages(),
    namespace_packages = ['virtualenvwrapper'],
    include_package_data = True,
    package_data = {
        '' : ['develop.sh']
    },
    scripts = [],
    classifiers = [
        'Intended Audience :: Developers',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Topic :: Software Development :: Libraries :: Python Modules'
    ],
    provides = ['virtualenvwrapper.develop'],
    requires = [
        'virtualenv',
        'virtualenvwrapper (>=2.0)'
    ],
    entry_points = {
        'virtualenvwrapper.initialize_source' : [
            'develop = virtualenvwrapper.develop:initialize_source'
        ]
    },
    zip_safe = False
)