from setuptools import setup, Extension, find_packages
from Cython.Distutils import build_ext

jscore_module = [
        Extension('jscore',
            ['jscore/jscore.pyx', ],
            language='c',
            include_dirs=['/home/nicolas/Projects/jhbuild/webkit/inst/include/webkit-1.0', ],
            library_dirs=['/home/nicolas/Projects/jhbuild/webkit/inst/lib', ],
            libraries=['webkit-1.0', ],
            runtime_library_dirs=['/home/nicolas/Projects/jhbuild/webkit/inst/lib',],
            extra_compile_args=['-ggdb3', ],
            extra_link_args=['-ggdb3', ],
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
