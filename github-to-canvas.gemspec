Gem::Specification.new do |s|
  s.name = 'github-to-canvas'
  s.version = '0.0.43'
  s.date = '2020-05-12'
  s.authors = ['maxwellbenton']
  s.email = 'maxwell@flatironschool.com'
  s.license = 'MIT'
  s.summary = 'github-to-canvas is a tool for migrating and aligning GitHub content with the Canvas LMS'
  s.files = Dir.glob('{bin,lib}/**/*') + %w[LICENSE.md README.md CONTRIBUTING.md Rakefile Gemfile]
  s.require_paths = ['lib']
  s.homepage = 'https://github.com/learn-co-curriculum/github-to-canvas'
  s.executables << 'github-to-canvas'
  s.add_runtime_dependency 'faraday', '~> 0.15'
  s.add_runtime_dependency 'redcarpet', '~> 3.5'
  s.add_runtime_dependency 'rest-client', '~> 2.1'
  s.add_runtime_dependency 'json', '~> 2.3'
end