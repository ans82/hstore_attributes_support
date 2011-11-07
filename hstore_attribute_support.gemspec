Gem::Specification.new do |s|
  s.name        = 'hstore_attribute_support'
  s.version     = '0.0.1'
  s.date        = '2011-11-07'
  s.summary     = "Adds AR Attributes support for Postgres hstore columns "
  s.description = "Adds AR Attributes support for Postgres hstore columns "
  s.authors     = ["Andreas Schwarzkopf"]
  s.email       = 'asmailbox@gmx.de'
  s.files       = Dir['lib/*.rb']
  s.homepage    = 'http://rubygems.org/gems/hstore_attributes_support'
  s.has_rdoc    = true

  s.add_dependency 'activerecord-postgres-hstore', '>= 0.1.2'
end