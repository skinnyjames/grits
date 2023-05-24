module Grits
  struct Subtransport
    include Mixins::Pointable
  
    def initialize(@raw : LibGit::SmartSubtransport*); end
  end

  class SubtransportStream < IO
    include Mixins::Pointable

    getter :bytes_read

    def initialize(@raw : LibGit::SmartSubtransportStream*, @buffer : LibC::Char*, @size : LibC::SizeT, @bytes_read : LibC::SizeT*? = nil)
      @slice = @buffer.to_slice(@size)
    end

    def trigger_write(io)
      io.each_byte do |byte|
        ptr = pointerof(byte)
        @raw.value.write.call(@raw, ptr, 1_u64)
      end
    end

    def read(slice : Bytes)
      #raise "Cannot read from writable stream" if @bytes_read.nil?
      fread = 0

      slice.size.times do |i|
        if @slice[i]?
          fread += 1
          slice[i] = @slice[i]
        end
      end

      @slice += fread
      @bytes_read.try {|r| r.value = fread.to_u64 }
      fread
    end

    def write(slice : Bytes) : Nil
      #raise "Cannot write to readable stream" unless @bytes_read.nil?

      slice.size.times do |i| 
        if slice[i]?
          @slice[i] = slice[i]
        end
      
      end

      @slice += slice.size

      @bytes_read.try {|r| r.value = slice.size.to_u64 }
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