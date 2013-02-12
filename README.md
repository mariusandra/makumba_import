Makumba Import
===

This gem provides functionality to use a database described by Makumba MDDs within your Rails application.

More specifically it generates a database schema and models matching what's described with the MDDs.

It supports all sorts of pointers, links, etc.

Update: now supports saving and creating new models. Keeps track of primary keys via Redis.


Usage
---

1. Configure your database.yml file to use the same database.

2. Add this to your Gemfile:

```
gem "makumba_import"
```

3. Add this to your Rakefile:

```
Dir["#{Gem.searcher.find('makumba_import').full_gem_path}/lib/tasks/*.rake"].each { |ext| load ext }
```

4. Generate a initializer called makumba_import.rb with the following contents:

```
MakumbaImport::Importer.set_mdd_path "/Users/marius/Projects/Cherry/cherry/web/WEB-INF/classes/dataDefinitions"
MakumbaImport::Importer.set_output_path "./" # where to generate the .rb files. Leave blank to import straight into the app folders

MakumbaImport::KeyHandler.set_dbsv 0
MakumbaImport::KeyHandler.init_redis REDIS   # set this to your Redis class

#MakumbaImport::KeyHandler.update_redis_keys  # uncomment once per server to store the latest keys per dbsv in redis
```

5. Run 

```
rake makumba_import:schema
rake makumba_import:models
```

Extra:

Use

```
SomeModel.first.to_ptr
```

to get the makumba pointer
