module Grits
  module Mixins
    module Pointable
      def raw
        @raw
      end

      def pointer
        pointerof(@raw)
      end
    end
  end
end
