module Grits
  alias PerformanceDataCb = (Wrappers::PerformanceData -> Void)
  alias FileModeType = LibGit::FilemodeT
  alias CloneLocalType = LibGit::CloneLocalT

  class CloneOptions
    include Mixins::Pointable
    include Mixins::Wrapper

    def self.default
      Error.giterr LibGit.clone_options_init(out opts, LibGit::GIT_CLONE_OPTIONS_VERSION), "Can't create clone options"
      new opts
    end

    wrap_value raw, version
    wrap_value raw, checkout_branch, true

    def initialize(@raw : LibGit::CloneOptions)
      @checkout_options = CheckoutOptions.new(to_unsafe.checkout_opts)
      @fetch_options = FetchOptions.new(to_unsafe.fetch_opts)
    end

    def bare=(bares : Bool)
      to_unsafe.bare = bares ? 1 : 0
    end

    def local=(type : CloneLocalType)
      to_unsafe.local = type
    end

    def on_repository_create(&block : RepositoryCreateCb)
      to_unsafe.repository_cb_payload = Box.box(block)
      to_unsafe.repository_cb = ->(repo : LibGit::Repository*, path : LibC::Char*, bare : LibC::Int, payload : Void*) do
        string_path = String.new(path)
        is_bare = bare.zero? ? false : true
        cb = Box(RepositoryCreateCb).unbox(payload)
        grepo = cb.call(string_path, is_bare)
        repo.value = grepo.to_unsafe
        0
      end
    end

    def on_remote_create(&block : RemoteCreateCb)
      to_unsafe.remote_cb_payload = Box.box(block)
      to_unsafe.remote_cb = ->(remote : LibGit::Remote*, repo : LibGit::Repository, name : LibC::Char*, url : LibC::Char*, payload : Void*) do
        rname = String.new(name)
        rurl = String.new(url)
        grepo = Repo.new(repo)
        cb = Box(RemoteCreateCb).unbox(payload)
        gremote = cb.call(grepo, rname, rurl)
        remote.value = gremote.to_unsafe
        0
      end
    end

    def checkout_options
      @checkout_options
    end

    def fetch_options
      @fetch_options
    end

    protected def computed_unsafe
      to_unsafe.checkout_opts = checkout_options.to_unsafe
      to_unsafe.fetch_opts = fetch_options.computed_unsafe
      to_unsafe
    end
  end
end
