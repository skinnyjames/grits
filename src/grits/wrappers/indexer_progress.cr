module Grits
  module Wrappers
    class IndexerProgress
      include Mixins::Wrapper

      def initialize(@indexer : LibGit::IndexerProgress*); end

      wrap indexer, total_objects
      wrap indexer, indexed_objects
      wrap indexer, recieved_objects
      wrap indexer, local_objects
      wrap indexer, total_deltas
      wrap indexer, indexed_deltas
      wrap indexer, recieved_bytes

      def percent_objects_indexed
        (indexed_objects / total_objects * 100).round(0)
      end

      def percent_objects_downloaded
        (recieved_objects / total_objects * 100).round(0)
      end

      def percent_deltas_indexed
        (indexed_deltas / total_deltas * 100).round(0)
      end
    end
  end
end