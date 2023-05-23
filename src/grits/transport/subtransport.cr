module Grits
  struct Subtransport
    include Mixins::Pointable

    def self.from_http
    
    end

    def self.from_git
    end


  
    def initialize(@raw : LibGit::SmartSubtransport*); end
  end

  struct SubtransportStream
    include Mixins::Pointable

    def initialize(@raw : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, size : LibC::SizeT, bytes_read : LibC::SizeT*?); end
  end

  struct Transport
    include Mixins::Pointable

    def initialize(@raw : LibGit::Transport*); end

    def call_check_certificate(cert : Wrappers::Certificate, hostname : String, valid : Bool)
      valid_int = valid ? 0 : 1

      Error.giterr(LibGit.transport_smart_certificate_check(self, cert, valid_int, hostname), "Could not check certificate")
    end

    def call_smart_credentials
     # Error.giterr(LibGit.transport_smart_credentials(out Credential*, self, ))
      
    end
  end
end