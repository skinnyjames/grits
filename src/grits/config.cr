module Grits
  class Config
    include Mixins::Pointable

    def initialize(@raw : LibGit::Config); end

    def mirror(name : String)
      Error.giterr LibGit.config_set_bool(to_unsafe, "remote.#{name}.mirror", 1), "Cannot set mirror in config"
    end

    def free
      LibGit.config_free(to_unsafe)
    end
  end
end