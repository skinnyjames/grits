module Grits
  module Mixins
    module Callbacks
      macro define_callback(method, block_type, var)
        def on_{{ method }}(&block : {{ block_type }})
          @{{ var }}.on_{{ method }}(&block)
        end
      end
    end
  end
end