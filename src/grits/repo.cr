require "file_utils"

module Grits
  alias RepositoryCreateCb = (String, Bool -> Grits::Repo) # not implemented

  class RepoInitOptions
    include Mixins::Wrapper
    include Mixins::Pointable

    def self.default
      Error.giterr LibGit.repository_init_options_init(out options, 1), "Couldn't init options"
      new(options)
    end

    wrap_value raw, version, true
    wrap_value raw, flags, true
    wrap_value raw, mode, true

    wrap_value raw, workdir_path, true
    wrap_value raw, description, true
    wrap_value raw, template_path, true
    wrap_value raw, initial_head, true
    wrap_value raw, origin_url, true

    def initialize(@raw : LibGit::RepositoryInitOptions); end
  end

  class Repo
    include Mixins::Pointable
    include Mixins::Wrapper
    include Mixins::Repo

    def self.open(path : String)
      Error.giterr LibGit.repository_open(out repo, path), "Couldn't open repository at #{path}"
      new(repo)
    end

    def self.open(*args, &block)
      repo = open(*args)
      yield repo
    ensure
      repo.free if repo
    end

    def self.open_bare(path : String)
      Error.giterr LibGit.repository_open_bare(out repo, path), "Couldn't open bare repository at #{path}"
      new(repo)
    end

    def self.open_bare(path : String)
      repo = open_bare(path)
      yield repo
    ensure
      repo.free if repo
    end

    def self.open_ext(path : String, flags : Array(Grits::OpenRepoType) = [OpenFlags::None], ceiling_dirs : String = "")
      flag_value = flags.map(&.value).reduce do |memo, val|
        memo | val
      end

      Error.giterr LibGit.repository_open_ext(out repo, path, flag_value, ceiling_dirs), "Can't open repo"
      new(repo)
    end

    def self.open_ext(path : String, **opts, &block)
      repo = open_ext(opts)
      yield repo
    ensure
      repo.free
    end

    def self.clone_mirror(
      url : String,
      path : String = Dir.cwd,
      options : CloneOptions = CloneOptions.default,
      &block
    )
      options.on_remote_create do |repo, name, url|
        repo.mirror_remote("origin", url)
      end

      options.bare = true
      repo = clone(url, path, options)

      yield repo
    ensure
      repo.free if repo
    end

    def self.clone(
      url : String,
      local_path : String = Dir.cwd,
      options : CloneOptions = CloneOptions.default
    )
      raw_options = options.computed_unsafe
      Error.giterr LibGit.clone(out repo, url, local_path, pointerof(raw_options)), "Can't clone repo"
      new(repo)
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
      new(repo)
    end

    def self.init(path : String, **args, &block) : Void
      repo = init(path, **args)
      yield repo
    ensure
      repo.free if repo
    end

    def self.init_ext(
      path : String,
      *,
      make : Bool? = false,
      mode : Int? = 511,
      options : RepoInitOptions = RepoInitOptions.default
    )
      FileUtils.mkdir_p(path, mode) if make && !Dir.exists?(path)
      Error.giterr LibGit.repository_init_ext(out repo, path, options.to_unsafe_ptr), "Couldn't init repository at #{path}"
      new(repo)
    end

    def self.init_ext(
      path : String,
      **args,
      &block
    )
      repo = init_ext(path, **args)
      yield repo
    ensure
      repo.free if repo
    end

    def initialize(@raw : LibGit::Repository)
    end

    def free
      LibGit.repository_free(to_unsafe)
    end

    def index
      Error.giterr LibGit.repository_index(out index, to_unsafe), "Index did not load for repository"
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

    def write_tree(&)
      index do |i|
        i.write_tree do |t|
          yield(t)
        end
      end
    end
  end
end
