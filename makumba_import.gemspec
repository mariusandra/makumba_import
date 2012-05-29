Gem::Specification.new do |s|
  s.name = 'makumba_import'
  s.version = '0.0.1'
  s.date = '2012-05-29'
  s.summary = "Makumba database integration with Rails applications"
  s.description = "Generate models matching your Makumba MDDs"
  s.authors = ["Marius Andra"]
  s.email = 'marius.andra@gmail.com'
  s.homepage = 'http://rubygems.org/gems/makumba_import'

  s.files        = Dir["{lib}/**/*.rb", "{lib}/**/*.rake", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'

  s.add_runtime_dependency "rubyzip"
  s.add_development_dependency "rubyzip"

end
