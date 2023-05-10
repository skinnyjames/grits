module Grits
  module Mixins
    module Wrapper
      macro wrap(instance_var_name, method_name, create_accessor=false)
        def {{ method_name }}
          @{{ instance_var_name }}.value.{{ method_name }}
        end

        {% if create_accessor %}
          def {{ method_name }}=(value)
            @{{ instance_var_name }}.value.{{ method_name }} = value
          end
        {% end %}
      end

      macro wrap_value(instance_var_name, method_name, create_accessor=false)
        def {{ method_name }}
          @{{ instance_var_name }}.{{ method_name }}
        end

        {% if create_accessor %}
          def {{ method_name }}=(value)
            @{{ instance_var_name }}.{{ method_name }} = value
          end
        {% end %}
      end

      protected def convert_to_strarray(strings : Array(String))
        strarray = LibGit::Strarray.new
        stuff = strings.reduce([] of Pointer(UInt8)) do |memo, ref|
          if a = ref
            memo << ref.to_unsafe
          end
          memo
        end
  
        strarray.strings = stuff
        strarray.count = stuff.size
        strarray
      end
    end
  end
end