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

    def self.next_primary_key(model)
      @redis.incr "maxprimary_#{model}_#{@dbsv}"
    end

    def self.update_redis_keys
      Dir[Rails.root.to_s + '/app/models/**/*.rb'].each do |file| 
        begin
          require file
        rescue
        end
      end

      models = ActiveRecord::Base.subclasses.collect { |type| type.name }.sort

      #p models

      models.each do |model|
        begin
          object      = Object.const_get(model)
          primary_key = object.primary_key
          current_max = object.unscoped.maximum(primary_key, :conditions => ["#{primary_key} > ? and #{primary_key} < ?", @dbsv << 24, (@dbsv + 1) << 24])
          redis_key   = "maxprimary_#{model}_#{@dbsv}"

          @redis.set redis_key, current_max
        rescue => e
          p e
        end
      end

    end

  end
end

