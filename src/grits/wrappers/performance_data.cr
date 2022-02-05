module Grits
  module Wrappers
    struct PerformanceData
      include Mixins::Wrapper

      def initialize(@perf : LibGit::CheckoutPerfdata*); end

      wrap perf, mkdir_calls
      wrap perf, stat_calls
      wrap perf, chmod_calls
    end
  end
end