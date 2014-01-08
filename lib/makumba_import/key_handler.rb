module MakumbaImport
  class KeyHandler

    @dbsv       = 0
    @redis      = nil

    def self.set_dbsv(dbsv)
      @dbsv = dbsv
    end

    def self.get_dbsv
      @dbsv
    end

    def self.init_redis(redis)
      @redis = redis
    end

    def self.next_primary_key(table_name)
      @redis.incr "maxprimary_#{table_name}_#{@dbsv}"
    end

    def self.update_redis_keys
      Dir[Rails.root.to_s + '/app/models/**/*.rb'].each do |file| 
        begin
          require file
        rescue
        end
      end

      models = ActiveRecord::Base.subclasses.select{|m| m.descends_from_active_record?}.collect { |type| type.name }.sort

      models.each do |model|
        begin
          object      = Object.const_get(model)
          primary_key = object.primary_key
          current_max = object.unscoped.maximum(primary_key, :conditions => ["#{primary_key} > ? and #{primary_key} < ?", @dbsv << 24, (@dbsv + 1) << 24]) || ((@dbsv << 24) + 1)
          redis_key   = "maxprimary_#{object.table_name}_#{@dbsv}"

          @redis.set redis_key, current_max
          puts "updated #{model} - #{object.table_name}"
        rescue => e
          puts "#{model} - #{e}"
        end
      end

    end

  end
end

