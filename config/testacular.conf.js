basePath = '../';

files = [
  JASMINE,
  JASMINE_ADAPTER,
  'public/lib/angular/angular.js',
  'public/lib/angular/angular-*.js',
  'public/lib/underscore/*.js',
  'public/lib/jquery/*.js',
  'public/lib/d3/*.js',
  'public/lib/angular-ui-bootstrap/ui-bootstrap-tpls-0.1.0.js',
  'test_frontend/lib/angular/angular-mocks.js',
  'public/js/**/*.js',
  'test_frontend/unit/**/*.js'
];

autoWatch = true;

browsers = ['Chrome'];

junitReporter = {
  outputFile: 'test_out/unit.xml',
  suite: 'unit'
};
