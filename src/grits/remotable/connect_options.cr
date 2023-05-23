module Grits
  alias RemoteRedirectType = LibGit::RemoteRedirectT

  struct RemoteConnectOptions
    include Mixins::Pointable
    include Mixins::Wrapper
    include Mixins::Callbacks

    @callbacks : Grits::Remotable::Callbacks

    wrap version, raw

    define_callback credentials_acquire, Remotable::CredentialsAcquireCb, callbacks
    define_callback certificate_check, Remotable::CertificateCheckCb, callbacks
    define_callback transfer_progress, Remotable::IndexerProgressCb, callbacks
    define_callback update_tips, Remotable::UpdateTipsCb, callbacks
    define_callback resolve_url, Remotable::ResolveUrlCb, callbacks

    def initialize(@raw : LibGit::RemoteConnectOptions*)
      @callbacks = Remotable::Callbacks.new(to_unsafe.callbacks)
    end

    def configure_proxy(&block : (ProxyOptions -> ProxyOptions))
      options = ProxyOptions.new(to_unsafe.proxy_opts)
      to_unsafe.proxy_opts = yield(options).computed_unsafe
    end

    def follow_redirects=(type : RemoteRedirectType)
      to_unsafe.follow_redirects = type
    end

    def headers=(value : Hash(String, String))
      # need to convert to strarray
    end

    protected def add_callbacks
      to_unsafe.callbacks = @callbacks.computed_unsafe
    end

    protected def computed_unsafe
      add_callbacks

      to_unsafe
    end
  end
end
