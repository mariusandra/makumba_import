Gem::Specification.new do |s|
  s.name = 'makumba_import'
  s.version = '0.2.0'
  s.date = '2013-02-12'
  s.summary = "Makumba database integration with Rails applications"
  s.description = "Generate models matching your Makumba MDDs"
  s.authors = ["Marius Andra"]
  s.email = 'marius.andra@gmail.com'
  s.homepage = 'https://github.com/marius0/makumba_import'

  s.files        = Dir["{lib}/**/*.rb", "{lib}/**/*.rake", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'

end
