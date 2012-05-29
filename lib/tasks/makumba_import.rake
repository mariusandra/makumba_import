require 'makumba_import'

namespace :makumba_import do
  desc 'Generate a new schema.rb file'
  task :schema => :environment do |t, args|
    schema = MakumbaImport::Importer::load_mdds
    MakumbaImport::Importer::generate_ruby_schema(schema)
  end
  
  desc 'Regenerate models'
  task :models => :environment do |t, args|
    schema = MakumbaImport::Importer::load_mdds
    MakumbaImport::Importer::generate_models(schema)
  end
  
end