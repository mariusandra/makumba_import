module MakumbaImport
  class Importer

    @mddPath = ""
    @outputPath = ""

    def self.setMddPath(mddPath)
      @mddPath = mddPath
    end

    def self.setOutputPath(outputPath)
      @outputPath = outputPath
    end

    def self.get_data(lines, mdd)
      fieldRegexp = /^([a-zA-Z\_]+)\s*=\s*([^;]+);?(.*)/
      fieldTypes = ["int", "text", "real", "date", "boolean", "binary", "file"]
      
      schema = {}
      schema[mdd] = {}
      primary = mdd.split(".").last
      schema[mdd][primary] = {'type' => 'primary'}
      
      lines.each do |line|
        unless line.match("^#") or line.strip == "" or line.match("->")
          if m = fieldRegexp.match(line)
            obj = {}
            field = m[1].strip
            attrs = m[2].strip
            comment = m[3] ? m[3].strip.gsub(/^;/,"").strip : ""
            
            attrs.split(" ").each do |attr|
              if fieldTypes.include?(attr)
                obj['type'] = attr
              end
              if attr.match(/fixed/)
                obj['not_null'] = true
              end
            end
            if m2 = attrs.match(/char\[(\d+)\]/)
              obj['type'] = "char"
              obj['length'] = m2[1]
            end
            if attrs.match(/set$/)
              newmdd = mdd+".."+field
              lines2 = []
              lines.each do |l|
                if l.start_with?(field+"->")
                  lines2.push l.gsub(field+"->", "")
                end
              end
              data2 = get_data(lines2, newmdd)
              schema.merge!(data2)
              schema[newmdd][primary] = {'type' => "ptr", 'ptr' => mdd}
            end
            if m3 = attrs.match(/int\s?\{([^\}]+)\}/)
              obj['type'] = "enum"
              obj['fields'] = {}
              # assuming there's no comma in the enum strings, (this is true for cherry)
              m3[1].split(",").each do |part|
                m4 = part.strip.match(/"([^"]+)"\s*=\s*(-?[0-9]+)/)
                obj['fields'][m4[2]] = m4[1]
              end
            end
            if m3 = attrs.match(/ptr\s+([a-zA-Z\.\_]+)/)
              obj['type'] = "ptr"
              obj['ptr'] = m3[1]
            end
            if m3 = attrs.match(/set\s+([a-zA-Z\.\_]+)/)
              newmdd = mdd+".."+field
              fieldname = m3[1].split('.').last
              schema[newmdd] = {}
              schema[newmdd][field] = {'type' => 'primary'}
              schema[newmdd][primary] = {'type' => "ptr", 'ptr' => mdd}
              schema[newmdd][fieldname] = {'type' => "ptr", 'ptr' => m3[1]}
            end
            if m3 = attrs.match(/set int\s?\{([^\}]+)\}/)
              fields = {}
              # assuming there's no comma in the enum strings, (this is true for cherry)
              m3[1].split(",").each do |part|
                m4 = part.strip.match(/"([^"]+)"\s*=\s*(-?[0-9]+)/)
                fields[m4[2]] = m4[1]
              end

              newmdd = mdd+".."+field
              schema[newmdd] = {}
              schema[newmdd][field] = {'type' => 'primary'}
              schema[newmdd][primary] = {'type' => "ptr", 'ptr' => mdd}
              schema[newmdd]['enum'] = {'type' => "set enum", 'fields' => fields}
            end
            if attrs.match(/not null/)
              obj['not_null'] = true
            end
            if attrs.match(/unique/)
              obj['unique'] = true
            end
            
            unless obj['type'].blank?
              schema[mdd][field] = obj 
            end
          end
          
        end
      end
      #puts schema
      schema
      
    end

    def self.load_mdds
      dir = @mddPath

      @files = Dir.glob(dir+"/*/*.mdd")
      @files |= Dir.glob(dir+"/*/*/*.mdd")
      @files |= Dir.glob(dir+"/*/*/*/*.mdd")
      
      schema = {}
      
      for file in @files
        unless File.directory?(file)
          filename = file.gsub(dir+"/", "").gsub(".mdd","")
          mdd = filename.gsub("/", ".")
          
          lines = open(file).map { |line| line }
          schema.merge!(get_data(lines, mdd))
        end
      end
      
      schema
    end

    def self.generate_ruby_schema(schema)
      
      txt = "# encoding: UTF-8\n\n";
      
      txt << "ActiveRecord::Schema.define(:version => "+Time.now.strftime("%Y%m%d%H%M%S")+") do\n\n"
      
      schema.each do |key, table|
        tablename = key.gsub(".", "_")
        lastpart = key.split(".").last
        
        txt << "  create_table \""+tablename+"_\", :force => true do |t|\n"
        
        table.each do |name, field|
          #type = "integer "
          type = field['type']
          type = "integer " if ["int", "primary", "ptr", "enum", "set enum"].include? field['type']
          type = "string  " if ["char"].include? field['type']
          type = "boolean " if ["boolean"].include? field['type']
          type = "datetime" if ["date"].include? field['type']
          type = "text    " if ["text"].include? field['type']
          type = "float   " if ["real"].include? field['type']
          
          enum = "";
          
          if field['type'] == "enum"
            enum = "\t\t # "
            field['fields'].each {|id,f| enum << id+" = \""+f+"\", "}
            enum = enum[0...-2]
          end

          txt << "    t."+type+" \""+name+"_\""+(field['not_null'].blank? ? "" : ",  :null => false")+enum+"\n"
          
          if field['type'] == 'primary'
            txt << "    t.datetime \"TS_modify_\",  :null => false\n"
            txt << "    t.datetime \"TS_create_\",  :null => false\n"
          end
          
        end
        
        txt << "  end\n\n"
        
        txt << "  add_index \""+tablename+"_\", [\""+lastpart+"_\"], :name => \""+lastpart+"_\", :unique => true\n"
        table.each do |name, field|
          unless field['unique'].blank?
            txt << "  add_index \""+tablename+"_\", [\""+name+"_\"], :name => \""+name+"_\", :unique => true\n"
          end
        end
        
        txt << "  \n\n"
        
      end
      
      txt << "end\n\n"
      
      File.open(@outputPath+"db/schema.rb", "w+") do |f|
        f.write(txt)
      end
    end

    def self.generate_models(schema)
      txt = '';
      newOnes = {}

      schema.clone.each do |key, table|
        table.each do |name, field|
          if ["ptr"].include? field['type']
            newOnes[field['ptr']] = {} if newOnes[field['ptr']].blank?
            newOnes[field['ptr']][key+"_"+name] = {"type" => "has_many", "primary_key" => name, "link_from" => key}
          end
        end
      end
      
      newOnes.each do |k, v|
        schema[k]['ref'] = v 
      end
      
      schema.each do |key, table|
        tablename = key.gsub(".", "_")
        lastpart = key.split(".").last
        filename = tablename.classify.tableize.singularize + '.rb';

        txt = ''
        txt << "# " + tablename.classify.tableize.singularize + ".rb\n\n"
        
        txt << "class "+tablename.classify+" < ActiveRecord::Base\n"
        txt << "  set_table_name \""+tablename+"_\"\n"
        txt << "  set_primary_key \""+lastpart+"_\"\n"
        txt << "  set_makumba_pointer_type \""+key+"\"\n\n"
        
        table.each do |name, field|
          if name == 'ref'
            field.each do |i, f|
              txt << "  has_many :"+f['link_from'].split('.').last.downcase.pluralize+", :foreign_key => '"+f['primary_key']+"_', :class_name => \""+f['link_from'].gsub(".","_").classify+"\"\n"
            end
          else
            #puts key
            if ["ptr"].include? field['type']
              txt << "  belongs_to :"+name.downcase+", :foreign_key => '"+name+"_', :class_name => '"+field['ptr'].gsub(".", "_").classify+"'\n"
              #puts "  belongs_to :"+name.downcase+", :foreign_key => '"+name+"_', :class_name => '"+field['ptr'].gsub(".", "_").classify+"'\n"
            end
          end
        end

        txt << "\n  fix_makumba_columns\n"
        
        txt << "end\n\n"

        File.open(@outputPath+"app/models/"+filename, "w+") do |f|
          f.write(txt)
        end

      end
      
      txt    
    end

  end
end