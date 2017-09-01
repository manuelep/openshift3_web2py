#!/usr/bin/env python

import os
import sys

here = os.environ['HOME']

rel_path_to_web2py = os.path.join('wsgi', 'web2py')
path_to_web2py = os.path.join(here, rel_path_to_web2py)

os.environ['web2py_path'] = path_to_web2py

sys.path.append(path_to_web2py)
sys.path.append(os.path.join(path_to_web2py, 'gluon'))

os.mkdir(os.path.join(path_to_web2py, 'logs'))

from gluon.settings import global_settings
from gluon.main import appfactory
WEB2PY_LOG = os.path.join(here, 'log', 'web2py.log')
application = appfactory(logfilename = WEB2PY_LOG)
