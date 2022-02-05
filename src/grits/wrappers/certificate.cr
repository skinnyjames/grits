module Grits
  module Wrappers
    class Certificate
      include Mixins::Wrapper

      def initialize(@cert : LibGit::GitCert*); end

      wrap cert, cert_type
    end
  end
end