module Grits
  class Config
    include Mixins::Pointable

    def initialize(@raw : LibGit::Config); end

    def set_bool(name : String, value : Bool)
      int = value ? 1 : 0
      Error.giterr LibGit.config_set_bool(to_unsafe, name, int), "Cannot set value of #{name}"
    end

    def get_bool(name : String)
      Error.giterr LibGit.config_get_bool(out int, to_unsafe, name), "Cannot get value of #{name}"
      int != 0
    end

    def mirror(name : String)
      set_bool("remote.#{name}.mirror", true)
    end

    def free
      LibGit.config_free(to_unsafe)
    end
  end
end