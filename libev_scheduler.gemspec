require_relative './lib/libev_scheduler/version'

Gem::Specification.new do |s|
  s.name        = 'libev_scheduler'
  s.version     = Libev::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Libev-based fiber scheduler for Ruby 3.0'
  s.author      = 'Sharon Rosner'
  s.email       = 'sharon@noteflakes.com'
  s.files       = `git ls-files`.split
  s.homepage    = 'https://github.com/digital-fabric/libev_scheduler'
  s.metadata    = {
    'source_code_uri' => 'https://github.com/digital-fabric/libev_scheduler',
    'homepage_uri' => 'https://github.com/digital-fabric/libev_scheduler',
    'changelog_uri' => 'https://github.com/digital-fabric/libev_scheduler/blob/master/CHANGELOG.md'
  }
  s.rdoc_options = ['--title', "libev_scheduler", '--main', 'README.md']
  s.extra_rdoc_files = ['README.md']
  s.extensions = ['ext/libev_scheduler/extconf.rb']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3.0'

  s.add_development_dependency 'rake-compiler',       '1.1.1'
  s.add_development_dependency  'minitest',           '5.16.1'
end
