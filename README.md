Makumba Import
===

This gem provides functionality to use a database described by Makumba MDDs within your Rails application.

More specifically it generates a database schema and models matching what's described with the MDDs.

It supports all sorts of pointers, links, etc.

Usage
---

Configure your database.yml file to use the same database.

Add this to your Rakefile:

```
Dir["#{Gem.searcher.find('makumba_import').full_gem_path}/lib/tasks/*.rake"].each { |ext| load ext }
```

Generate a initializer called makumba_import.rb with the following contents:

```
MakumbaImport::Importer.setMddPath "/..your.path../WEB-INF/classes/dataDefinitions"
MakumbaImport::Importer.setOutputPath "./" # where to generate the .rb files. Leave blank to import straight into the app folders
```

Run rake makumba_import:schema and rake makumba_import:models.
