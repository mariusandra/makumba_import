Dir["tasks/**/*.rake"].each { |ext| load ext } if defined?(Rake)

require 'open-uri'
require 'fileutils'

require 'makumba_import/importer'
require 'makumba_import/legacy'
