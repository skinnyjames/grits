module Grits
  struct ProxyOptions
    include Mixins::Pointable
    include Mixins::Callbacks

    alias ProxyType = LibGit::ProxyT

    def initialize(@raw : LibGit::ProxyOptions, @callbacks = Remote::Callbacks.init); end

    def type=(t : ProxyType)
      to_unsafe.type = t
    end

    def url=(url)
      to_unsafe.url = url
    end

    define_callback credentials_acquire, Remote::CredentialsAcquireCb, callbacks
    define_callback certificate_check, Remote::CertificateCheckCb, callbacks

    protected def computed_unsafe
      unless @callbacks.empty?
        callbacks = @callbacks.computed_unsafe
        to_unsafe.credentials = callbacks.credentials
        to_unsafe.certificate_check = callbacks.certificate_check
        to_unsafe.payload = callbacks.payload
      end

      to_unsafe
    end
  end

  struct FetchOptions
    alias PruneOptions = LibGit::FetchPruneT
    alias TagOptions = LibGit::RemoteAutotagOptionT

    include Mixins::Pointable
    include Mixins::Wrapper
    include Mixins::Callbacks

    @callbacks : Grits::Remote::Callbacks

    def initialize(@raw : LibGit::FetchOptions)
      @callbacks = Remote::Callbacks.new to_unsafe.callbacks
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
      strarr.strings = arr
      strarr.count = arr.count
      to_unsafe.custom_headers = strarr
    end

    define_callback credentials_acquire, Remote::CredentialsAcquireCb, callbacks
    define_callback certificate_check, Remote::CertificateCheckCb, callbacks
    define_callback transfer_progress, Remote::IndexerProgressCb, callbacks
    define_callback update_tips, Remote::UpdateTipsCb, callbacks
    define_callback resolve_url, Remote::ResolveUrlCb, callbacks

    protected def computed_unsafe
      to_unsafe.callbacks = @callbacks.computed_unsafe

      to_unsafe
    end
  end
end