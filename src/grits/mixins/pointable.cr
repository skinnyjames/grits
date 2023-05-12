module Grits
  module Mixins
    module Pointable
      protected def to_unsafe
        @raw
      end

      protected def to_unsafe_ptr
        pointerof(@raw)
      end

      protected def copy_to_string(char_ptr) : String?
        return nil if char_ptr.null?

        String.new(char_ptr)
      end

      protected def copy_non_terminated_to_string(char_ptr, size)
        return nil if char_ptr.null?

        String.build do |io|
          io.write char_ptr.to_slice(size)
          io << '\0'
        end
      end
    end
  end
end
