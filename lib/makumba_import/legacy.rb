module LegacyMakumba

  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end
  module ClassMethods
    def fix_makumba_columns
      column_names.each do |old_name|
        if old_name.match(/_$/)
          new_name = old_name[0...-1]
          unless self.method_defined? new_name
            self.send(:define_method, new_name) { self.send(old_name) }
            self.send(:define_method, "#{new_name}=") { |value| self.send("#{old_name}=", value) }
            self.send(:define_method, "find_by_#{new_name}") { |value| self.send("find_by_#{old_name}", value) }
          end
        end
      end

      self.send(:before_save, :update_makumba_fields)
    end

    def set_makumba_pointer_type(type)
      self.send(:define_method, "pointer_type") { type }
    end
  end

  def update_makumba_fields
    self.id = next_primary_key if self.id.blank?
    self.TS_create = Time.new if self.TS_create.blank?
    self.TS_modify = Time.new
  end

  def next_primary_key
    MakumbaImport::KeyHandler.next_primary_key(self.class.name)
  end

  def to_ptr
    def crc(v)
      r = 0
      32.times do
        if (v & 1) == 1
          r = r + 1
        end
        v = v >> 1;
      end
      r
    end

    # http://www.func09.com/wordpress/archives/228
    def to_hashcode(str)
      max = 2 ** 31 - 1
      min = -2 ** 31
      h = 0
      n = str.size
      n.times do |i|
        h = 31 * h + str[i].ord
        while h < min || max < h
          h = max - ( min - h  ) + 1 if h < min
          h = min - ( max - h  ) - 1 if max < h
        end
      end
      h
    end

    n = self.id

    hc = to_hashcode(pointer_type) & "ffffffffl".to_i(16)
    ((crc(n) & "fl".to_i(16)) << 32 | n ^ hc).to_s(36)
  end

end

class ActiveRecord::Base
  include LegacyMakumba

  def self.last_primary_key(dbsv = MakumbaImport::KeyHandler.get_dbsv)
    self.select("max(#{primary_key}) as biggest").where("#{primary_key} > ? and #{primary_key} < ?", dbsv << 24, (dbsv + 1) << 24).first.biggest || (dbsv << 24)
  end

end
