require "file_utils"

module Grits
  class Repo
    include Mixins::Pointable
    include Mixins::Repo

    def self.open(path : String)
      Error.giterr LibGit.repository_open(out repo, path), "Couldn't open repository at #{path}"
      new(repo, path)
    end

    def self.open(*args, &block)
      repo = open(*args)
      yield repo
    ensure
      repo.free if repo
    end

    def self.clone(
      url : String,
      local_path : String = Dir.cwd
    )
      Error.giterr LibGit.clone_options_init(out options, LibGit::GIT_CLONE_OPTIONS_VERSION), "Can't create clone options"
      Error.giterr LibGit.clone(out repo, url, local_path, pointerof(options)), "Can't clone repo"
      new(repo, local_path)
    end

    def self.clone(*args, &block)
      repo = clone(*args)
      yield repo
    ensure
      repo.free if repo
    end

    def self.init(
      path : String,
      *,
      bare : Bool? = false,
      make : Bool? = false,
      mode : Int? = 511,
      bare_int : UInt32 = (bare ? 1 : 0).to_u
    )
      FileUtils.mkdir_p(path, mode) if make && !Dir.exists?(path)
      Error.giterr LibGit.repository_init(out repo, path, bare_int), "Couldn't init repository at #{path}"
      new(repo, path)
    end

    def self.init(path : String, **args, &block) : Void
      repo = init(path, **args)
      yield repo
    ensure
      repo.free if repo
    end

    def initialize(@raw : LibGit::Repository, @path : String)
    end

    def free
      LibGit.repository_free(@raw)
    end

    def index
      Error.giterr LibGit.repository_index(out index, @raw), "Index did not load for repository"
      Index.new(index, self)
    end

    def index(&block)
      i = index
      begin
        yield i
      ensure
        i.free
      end
    end
  end
end
