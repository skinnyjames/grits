module Grits
  module Mixins
    module Wrapper
      macro wrap(instance_var_name, method_name)
        def {{ method_name }}
          @{{ instance_var_name }}.value.{{ method_name }}
        end
      end
    end
  end
end