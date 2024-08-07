fs = import('fs')

subdir('exceptions')

sources = files(
  'MTXClient.m',
  'MTXRequest.m',
  'MTXSQLite3Storage.m',
)

objmatrix = library('objmatrix',
  sources + exceptions_sources,
  include_directories: incdir,
  dependencies: objfw_dep,
  soversion: '0.0.0',
  install: true)

headers = ['MTXStorage.h', 'ObjMatrix.h']
foreach source: sources + exceptions_sources
  headers += fs.replace_suffix(source.full_path(), '.h')
endforeach

install_headers(headers, subdir: 'ObjMatrix')
