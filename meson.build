project('ObjMatrix', 'objc',
  version: '0.1',
  meson_version: '>= 1.5.0',
  default_options: {
    'b_asneeded': 'false',
    'warning_level': '3',
  })

objfw_dep = dependency('objfw', modules: ['ObjFWTLS', 'ObjSQLite3'])

incdir = include_directories('src', 'src/exceptions')

subdir('src')
subdir('tests')

objfwconfig = find_program('objfw-config')
packages_dir = run_command(
  [objfwconfig, '--packages-dir'],
  check: true).stdout().strip()

configure_file(
  input: 'ObjMatrix.oc.in',
  output: 'ObjMatrix.oc',
  configuration: {
    'libdir': get_option('prefix') / get_option('libdir'),
  },
  install: true,
  install_dir: packages_dir)
