module Grits
  alias CheckoutProgressCb = (String, UInt64, UInt64 -> Void)
  alias CheckoutNotifyCb = (CheckoutNotifyType, String, DiffFile, DiffFile, DiffFile -> Void)
  alias CheckoutNotifyType = LibGit::CheckoutNotifyT
  alias PerformanceDataCb = (Wrappers::PerformanceData -> Void)
  alias FileModeType = LibGit::FilemodeT
  alias CloneLocalType = LibGit::CloneLocalT
  alias RepositoryCreateCb = (String, Bool -> Grits::Repo) # not implemented
  alias RemoteCreateCb = (Repo, String, String -> Grits::Remote)
  class CheckoutOptions
    include Mixins::Pointable
    include Mixins::Wrapper

    wrap_value raw, version
    wrap_value raw, dir_mode, true
    wrap_value raw, file_mode, true
    wrap_value raw, fild_open_flags, true
    wrap_value raw, notify_flags, true
    wrap_value raw, target_directory, true
    wrap_value raw, ancestor_label
    wrap_value raw, our_label
    wrap_value raw, their_label

    def disable_filters=(disable : Bool)
      to_unsafe.disable_filters = disable ? 1 : 0
    end

    def initialize(@raw : LibGit::CheckoutOptions)
    end

    def paths=(pathspec = [] of String)
      strarr = LibGit::Strarray.new
      strarr.strings = pathspec.map &.to_unsafe
      strarr.count = pathspec.size

      to_unsafe.paths = strarr
    end

    def on_performance_data(&block : PerformanceDataCb)
      @raw.perfdata_payload = Box.box(block)
      @raw.perfdata_cb = ->(perfdata : LibGit::CheckoutPerfdata*, payload : Void*) do
        cb = Box(PerformanceDataCb).unbox(payload)
        cb.call(Wrappers::PerformanceData.new(perfdata))
      end
    end

    def on_notify(flags : CheckoutNotifyType = CheckoutNotifyType::All, &block : CheckoutNotifyCb)
      @raw.notify_flags = flags
      @raw.notify_payload = Box.box(block)
      @raw.notify_cb = ->(why : LibGit::CheckoutNotifyT, path : LibC::Char*, baseline : LibGit::DiffFile*, target : LibGit::DiffFile*, workdir : LibGit::DiffFile*, payload : Void*) do
        cb = Box(CheckoutNotifyCb).unbox(payload)
        string_path = String.new(path)
        cb.call(why, string_path, DiffFile.new(baseline), DiffFile.new(target), DiffFile.new(workdir))
        0
      end
    end

    def on_progress(&block : CheckoutProgressCb)
      @raw.progress_payload = Box.box(block)
      @raw.progress_cb = ->(path : LibC::Char*, completed_steps : LibC::SizeT, total_steps : LibC::SizeT, payload : Void*) do
        string_path = path.null? ? "(null)" : String.new(path)
        cb = Box(CheckoutProgressCb).unbox(payload)
        cb.call(string_path, completed_steps, total_steps)
      end
    end
  end

  # todo: repository_callback and remote_callback
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
