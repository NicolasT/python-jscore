import os
import commands

from setuptools import setup, Extension, find_packages
from Cython.Distutils import build_ext

#Figure out webkit build flags
webkit_package = 'webkit-1.0'

#Find pkg-config
status, _ = commands.getstatusoutput('pkg-config --version')
if not status == 0:
    raise Exception('Unable to run pkg-config, is it installed?')

#Find webkit package
status, _ = commands.getstatusoutput('pkg-config %s' % webkit_package)
if not status == 0:
    raise Exception('Unable to find package %s, can pkg-config find it?' %
            webkit_package)

#Find webkit cflags
status, webkit_cflags = commands.getstatusoutput('pkg-config --cflags %s' %
        webkit_package)
if not status == 0:
    raise Exception('Unable to find package %s cflags' % webkit_package)
webkit_include_dirs = list()
s = webkit_cflags.split()
for i in s:
    if i.startswith('-I'):
        webkit_include_dirs.append(i[2:])

#Find out webkit ldflags
status, webkit_ldflags = commands.getstatusoutput('pkg-config --libs %s' %
        webkit_package)
if not status == 0:
    raise Exception('Unable to find package %s ldflags' % webkit_package)
webkit_library_dirs = list()
s = webkit_ldflags.split()
for i in s:
    if i.startswith('-L'):
        webkit_library_dirs.append(i[2:])

#Some customizations
extra_compile_args = list()
extra_link_args = list()
#Enable debug by default for now
if 'DISABLE_DEBUG' not in os.environ:
    extra_compile_args.append('-ggdb3')
    extra_link_args.append('-ggdb3')
#Enable rpath for now, if able to find out
runtime_library_dirs = list()
if 'DISABLE_RPATH' not in os.environ:
    status, webkit_libflags = commands.getstatusoutput(
        'pkg-config --libs-only-L %s' % webkit_package)
    if not status == 0:
        raise Exception('Unable to find package %s library folder' %
                webkit_package)
    s = webkit_libflags.split()
    if len(s) > 1 and not s[0].startswith('-L'):
        raise Exception('Unable to parse library folder string: %s' %
                webkit_libflags)
    webkit_library_path = s[0][2:]
    runtime_library_dirs.append(webkit_library_path)

jscore_module = [
        Extension('jscore',
            ['jscore/jscore.pyx', ],
            language='c',
            include_dirs=webkit_include_dirs,
            library_dirs=webkit_library_dirs,
            libraries=['webkit-1.0', ],
            extra_compile_args=['-Werror', ] + extra_compile_args,
            extra_link_args=extra_link_args,
            runtime_library_dirs=runtime_library_dirs,
        )
]

setup(name='python-jscore',
      version='0.1',
      packages=find_packages(exclude=['test', ]),

      author='Nicolas Trangez',
      author_email='ikke@nicolast.be',
      description='Python bindings to the JavaScriptCore library',
      keywords='javascript javascriptcore jscore webkit',

      ext_modules=jscore_module,
      package_data={
          '': ['*.pyx', ],
      },
      cmdclass={
          'build_ext': build_ext,
      },
      test_suite='nose.collector',
)
