module Grits
  module Mixins
    module Pointable
      protected def to_unsafe
        @raw
      end

      protected def to_unsafe_ptr
        pointerof(@raw)
      end
    end
  end
end
