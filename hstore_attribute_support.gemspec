Gem::Specification.new do |s|
  s.name          = 'hstore_attribute_support'
  s.version       = '0.0.5'
  s.date          = '2011-11-16'
  s.summary       = "Adds AR Attributes support for Postgres hstore columns "
  s.description   = "Adds AR Attributes support for Postgres hstore columns "
  s.authors       = ["Andreas Schwarzkopf"]
  s.email         = 'asmailbox@gmx.de'
  s.homepage      = 'http://rubygems.org/gems/hstore_attributes_support'
  s.has_rdoc      = true
  s.rdoc_options  = ['--charset=UTF-8']
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  #s.add_dependency 'activerecord-postgres-hstore', '>= 0.1.2'
end