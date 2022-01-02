module Grits
  module Mixins
    module Pointable
      def value
        @raw
      end

      def raw
        @raw
      end

      def pointer
        pointerof(@raw)
      end
    end
  end
end
