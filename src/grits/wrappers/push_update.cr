module Grits
  module Wrappers
    class PushUpdate
      include Mixins::Pointable
      include Mixins::Wrapper

      def initialize(@raw : LibGit::PushUpdate*); end

      def source_name
        String.new(to_unsafe.src_refname)
      end

      def destination_name
        String.new(to_unsafe.dst_refname)
      end

      def source
        Oid.new(pointerof(to_unsafe.src))
      end

      def destination
        Oid.new(pointerof(to_unsafe.dst))
      end
    end
  end
end