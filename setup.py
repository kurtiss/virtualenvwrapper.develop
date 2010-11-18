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

execfile(os.path.join('src', 'virtualenvwrapper', 'develop', 'version.py'))


setup(
    name = 'virtualenvwrapper.develop',
    version = VERSION,
    description = 'Developer extensions to virtualenvwrapper.',
    author = 'Kurtiss Hare',
    author_email = 'kurtiss@gmail.com',
    url = 'http://www.github.com/kurtiss/virtualenvwrapper.develop',
    packages = find_packages('src'),
    namespace_packages = ['virtualenvwrapper'],
    include_package_data = True,
    package_dir = {'':'src'},
    package_data = {
        '' : [
            'develop.sh', 
            'newproject/__init__.py.txt',
            'newproject/version.py.txt',
            'newproject/gitignore.txt',
            'newproject/postactivate.txt',
            'newproject/predeactivate.txt',
            'newproject/README.txt',
            'newproject/setup.py.sample.txt',
            'newproject/pip_develop.txt',
        ]
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