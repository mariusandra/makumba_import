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
          self.send(:define_method, new_name) { self.send(old_name) }
          self.send(:define_method, "#{new_name}=") { |value| self.send("#{old_name}=", value) }
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include LegacyMakumba
end
