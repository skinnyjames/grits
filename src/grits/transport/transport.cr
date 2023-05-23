module Grits
  struct Subtransport
    include Mixins::Pointable

    def self.from_http
    
    end

    def self.from_git
    end


  
    def initialize(@raw : LibGit::SmartSubtransport*); end
  end

  class SubtransportStream < IO
    include Mixins::Pointable

    def initialize(@raw : LibGit::SmartSubtransportStream*, @buffer : LibC::Char*, @size : LibC::SizeT, @bytes_read : LibC::SizeT*? = nil)
      @slice = @buffer.to_slice(@size)
    end

    def read(slice : Bytes)
      raise "Cannot read from writable stream" if @bytes_read.nil?

      slice.size.times { |i| slice[i] = @slice[i] }

      @slice += slice.size
      @bytes_read.value = slice.size
      @bytes_read.value
    end

    def write(slice : Bytes) : Nil
      raise "Cannot write to readable stream" unless @bytes_read.nil?

      slice.size.times { |i| @slice[i] = slice[i] }
      @slice += slice.size
    end
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