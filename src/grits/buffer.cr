module Grits
  class Buffer
    include Mixins::Pointable

    def self.create
      buff = LibGit::Buf.new
      new(buff)
    end

    def initialize(@raw : LibGit::Buf); end

    def to_s
      String.new(to_unsafe.ptr)
    end

    def <<(value : String)
      LibGit.buf_set(to_unsafe_ptr, value, value.size)
    end

    def free
      LibGit.buf_free(to_unsafe_ptr)
    end
  end
end