#! /usr/bin/env python
import sys
import itertools
import re
import importlib
import types

type1_import = re.compile('import (.*)')
type2_import = re.compile('from\s+(?P<base>[a-zA-Z0-9_.]+)\s+import\s+(?P<imp_string>[^\*]+)')
type3_import = re.compile('from\s+(?P<base>[a-zA-Z0-9_.]+)\s+import\s+\*')

module_match = re.compile('(?P<py_name>[a-zA-Z0-9_.]+)(\s+as\s+(?P<alias>[a-zA-Z0-9_.]+))?')

global_completer = []

global_completer_name = '@GLOBAL'

KWD_JOINER = '$'
KEY_JOINER = '#'
ENTRY_JOINER = '!'

mappings = dict()

def parse_imp_string(base, imp_string):
    """ imp_string is a string of the form <pyobj> (as <alias>)? or more delimited by commas
    return a dictionary of mappings <id, keywords>"""
    if imp_string == None:
        return 
    for module_part in imp_string.strip().split(','):
        parse_module_stmt(base, module_part.strip())


def extract_valid_keywords(module):
    """ given a module, extract the valid keywords we want to match on.
    The Rule we will use is, anything that doesnt start with a _ and whose type is not module """
    all_list = getattr(module, '__all__', None)
    mod_list = all_list if all_list != None else dir(module)
    filter_attrs = lambda a: True if a[0] != '_' and type(getattr(module, a, None)) != types.ModuleType else False
    return filter(filter_attrs, mod_list)

def parse_module_stmt(base, s):
    """ parses a string of the form "<pyobj>( as <alias>)? and returns a tuple (id, keywords) 
    or None if it fails"""

    match = module_match.match(s)
    if match: 
        matches = match.groupdict()
        pyobj = matches.get('py_name', None)
        alias = matches.get('alias', None)
        if base == None:
            # type 1, if it fails to import then return None
            try:
                mod = importlib.import_module(pyobj)
                kwd_list = extract_valid_keywords(mod)
                key = alias if alias != None else pyobj
                if len(kwd_list) > 0:
                    mappings[key] = kwd_list
            except ImportError:
                return
        else:
            # if its type 2, need to check if pyobj is a module or function
            full_import = "%s.%s" % (base, pyobj)
            try: 
                mod = importlib.import_module(full_import)
                kwd_list = extract_valid_keywords(mod)
                key = alias if alias != None else pyobj
                if len(kwd_list) > 0:
                    mappings[key] = kwd_list
            except ImportError:
                # add the pyobj to global completer
                global_completer.append(pyobj)


def parse_import(s):
    """ return a tuple (id, keywords) where id is the of the module 
    ('' if global) and keywords is list of keywords to match """ 

    match = type1_import.match(s)
    if match:
        imp_string = match.group(1)
        parse_imp_string(None, imp_string) 
    else:
        match = type2_import.match(s)
        if match:
            matches = match.groupdict()
            base = matches.get('base', None)
            imp_string = matches.get('imp_string', None)
            parse_imp_string(base, imp_string) 

        else:
            match = type3_import.match(s)
            if match:
                matches = match.groupdict()
                base = matches.get('base', None)
                try:
                    mod = importlib.import_module(base)
                    kwd_list = extract_valid_keywords(mod)
                    global_completer.extend(kwd_list)
                except ImportError:
                    print 'failed to import %s' % base
                    return 

def parse_file(file_name):
    with open(file_name) as fin:
        for line in fin:
            parse_import(line.strip())

def print_dict(mapping):
    def expand_entry(mapping, key):
        kwds = KWD_JOINER.join(mapping[key])
        return KEY_JOINER.join([key, kwds])
    mapping_list = [expand_entry(mapping, key) for key in mapping.keys()]
    return ENTRY_JOINER.join(mapping_list)

def test_function(file_name, sys_path):
    sys.path.append(sys_path)

    parse_file(file_name)
    for key in mappings.keys():
        print key
        print mappings[key]
        print '\n'
    print "global Completer is"
    print global_completer

if __name__ == '__main__':

    print len(sys.argv)
    if len(sys.argv) < 3:
        sys.exit()
    # first argument is file name
    file_name = sys.argv[1]
    # second file name is directory, to add to python path
    sys.path.append(sys.argv[2])

    parse_file(file_name)
    mappings[global_completer_name] = global_completer

    sys.stdout.write(print_dict(mappings))
    
    
    





