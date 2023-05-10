module Grits
  module Mixins
    module Callbacks
      # includer should make an method
      # that 
      abstract def add_callbacks

      macro define_callback(method, block_type, var)
        def on_{{ method }}(&block : {{ block_type }})
          @{{ var }}.on_{{ method }}(&block)
        end
      end
    end
  end

  # CallbacksState helps when multiple callbacks
  # share the same payload.
  class CallbacksState
    getter :callbacks

    macro define_callback(type, key)
      def on_{{ key }}(&block : {{ type }})
        @callbacks <<  :{{ key }}

        @on_{{ key }} = block
      end

      def on_{{ key }}
        @on_{{ key }}
      end
    end

    def initialize
      @callbacks = [] of Symbol
    end

    def empty?
      @callbacks.empty?
    end
  end
end
