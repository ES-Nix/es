from setuptools import setup, find_packages

setup(
      name='fl4sk',
      version='1.0',
      # Modules to import from other scripts:
      # packages=find_packages(),
      packages=['fl4sk'],
      # package_dir={'Package': 'src'},
      entry_points={'console_scripts': ['fl4sk = fl4sk.__main__:main']},
     )
