require "file_utils"

module Grits
  class Repo
    include Mixins::Pointable

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

    def self.init(
      path : String, *,
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

    getter index : Grits::Index
    @active_commits : Array(Commit) = [] of Commit

    def initialize(@raw : LibGit::Repository, @path : String)
      @index = get_index
    end

    def add(path : String) : Void
      index.add(path)
      index.write
    end

    # default signature, ref, etc
    def commit(message)
      builder = CommitBuilder.build(self, message: message) do |builder|
        builder.sign_with_defaults!
      end
      builder.commit!
    end

    def build_commit(&block)
      CommitBuilder.build(self, &block)
    end

    def bare?
      LibGit.repository_is_bare(@raw) == 1
    end

    def empty?
      LibGit.repository_is_empty(@raw) == 1
    end

    def workdir
      String.new LibGit.repository_workdir(@raw)
    end

    def free
      @active_commits.each &.free
      index.free
      LibGit.repository_free(@raw)
    end

    def index
      @index
    end

    private def get_index
      Error.giterr LibGit.repository_index(out index, @raw), "Index did not load for repository"
      Index.new(index)
    end
  end
end
