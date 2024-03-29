module Grits
  struct FetchOptions
    alias PruneOptions = LibGit::FetchPruneT
    alias TagOptions = LibGit::RemoteAutotagOptionT

    include Mixins::Pointable
    include Mixins::Wrapper
    include Mixins::Callbacks

    @callbacks : Grits::Remotable::Callbacks

    def self.default
      Error.giterr LibGit.fetch_options_init(out fetch_opts, LibGit::GIT_CLONE_OPTIONS_VERSION), "Cant create fetch options"
      new(fetch_opts)
    end

    def initialize(@raw : LibGit::FetchOptions)
      @callbacks = Remotable::Callbacks.new to_unsafe.callbacks
    end

    def prune=(is_pruning : PruneOptions)
      to_unsafe.prune = is_pruning
    end

    def update_fetchhead=(update : Bool)
      to_unsafe.update_fetchhead = bool ? 0 : 1
    end

    def download_tags=(type : TagOptions)
      to_unsafe.download_tag = type
    end

    def configure_proxy(&block : (ProxyOptions -> ProxyOptions))
      options = ProxyOptions.new(to_unsafe.proxy_opts)
      to_unsafe.proxy_opts = yield(options).computed_unsafe
    end

    def headers=(headers : Hash(String, String))
      strarr = LibGit::Strarray.new
      arr = headers.reduce([] of String) do |memo, (k,v)|
        memo << "#{k}: #{v}"
        memo
      end
      strarr.strings = arr.map &.to_unsafe
      strarr.count = arr.count
      to_unsafe.custom_headers = strarr
    end

    define_callback credentials_acquire, Remotable::CredentialsAcquireCb, callbacks
    define_callback certificate_check, Remotable::CertificateCheckCb, callbacks
    define_callback transfer_progress, Remotable::IndexerProgressCb, callbacks
    define_callback update_tips, Remotable::UpdateTipsCb, callbacks
    define_callback resolve_url, Remotable::ResolveUrlCb, callbacks

    protected def add_callbacks
      to_unsafe.callbacks = @callbacks.computed_unsafe
    end

    protected def computed_unsafe
      add_callbacks

      to_unsafe
    end
  end
end