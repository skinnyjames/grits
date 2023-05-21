module Grits
  class Transport
    include Mixins::Pointable
    getter :remote

    def initialize(@remote : Remote, @raw : LibGit::Transport); end
  end
end
