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
          end
        end
      end
    end

    def set_makumba_pointer_type(type)
      self.send(:define_method, "pointer_type") { type }
    end
  end

  def toExternalForm
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
end
