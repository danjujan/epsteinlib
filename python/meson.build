# SPDX-FileCopyrightText: 2024 Jan Schmitz <schmitz@num.uni-sb.de>
#
# SPDX-License-Identifier: CC0-1.0

py_mod = import('python')
py = py_mod.find_installation(pure: false)

if host_machine.system() == 'darwin' and py.language_version() == '3.8'
    # This fixes build failure on MacOS with Python 3.8
    add_project_arguments('-Wno-deprecated-declarations', language: 'c')
endif

py.extension_module(
    'epsteinlib',
    'epsteinlib.pyx',
    link_whole: epsteinlib.get_static_lib(),
    install: true,
)
# Install stub file
py.install_sources('epsteinlib.pyi')

python_module_build_dir = meson.current_build_dir()
subdir('tests')
