import parse_imports
import importlib
import os
import sys

sys.path.append('/home/mik')
print sys.path
os.environ['DJANGO_SETTINGS_MODULE'] = 'mik_site.settings'


mod = importlib.import_module('django.db.models') 
x = parse_imports.extract_valid_keywords(mod)
print x
