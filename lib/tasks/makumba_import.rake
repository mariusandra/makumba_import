require 'makumba_import'

namespace :makumba_import do
  desc 'Generate a new schema.rb file'
  task :schema => :environment do |t, args|

    schema = MakumbaImport::Importer::load_mdds

    #MakumbaImport::Importer::generate_ruby_schema(schema)
  end
  
  desc 'Regenerate models'
  task :models => :environment do |t, args|
    schema = MakumbaImport::Importer::load_mdds
    #MakumbaImport::Importer::generate_models(schema)
  end

  # def convert
  #   dataDefinitions = "/home/marius/Projects/JSP/cherry/web/WEB-INF/classes/dataDefinitions"
    
  #   schema = load_mdds(dataDefinitions)
    
  #   # generate_ruby_schema(schema)
  #   generate_models(schema)
    
  #   puts schema["product.Daily"]
    
  # end

  # desc 'pull geonames data, load into db, then clean up after itself'
  # task :run => :environment do
  #   puller = GeonamesRails::Puller.new
  #   writer = ENV['DRY_RUN'] ? GeonamesRails::Writers::DryRun.new : GeonamesRails::Writers::ActiveRecord.new
  #   GeonamesRails::Loader.new(puller, writer).load_data
  # end
  
  # desc 'load the data from files you already have laying about'
  # task :load => :environment do
  #   writer = ENV['DRY_RUN'] ? GeonamesRails::Writers::DryRun.new : GeonamesRails::Writers::ActiveRecord.new
  #   GeonamesRails::Loader.new(nil, writer).load_data
  # end
  
end