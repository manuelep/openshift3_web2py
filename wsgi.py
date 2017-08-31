#!/usr/bin/env python

import os
import sys

here = os.path.realpath(__file__)

rel_path_to_web2py = os.path.join('wsgi', 'web2py')
path_to_web2py = os.path.join(here, rel_path_to_web2py)

sys.path.append(path_to_web2py)
sys.path.append(os.path.join(path_to_web2py, 'gluon'))

from gluon.settings import global_settings
from gluon.main import appfactory
WEB2PY_LOG = os.path.join(here, 'log', 'web2py.log')
application = appfactory(logfilename = WEB2PY_LOG)

application = get_app()
