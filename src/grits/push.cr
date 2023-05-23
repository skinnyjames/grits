module Grits
  class Push
    include Mixins::Pointable

    def initialize(@raw : LibGit::Push); end

    def to_unsafe
      @raw
    end
  end
end
