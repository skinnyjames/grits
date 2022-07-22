module Grits
  struct ProxyOptions
    include Mixins::Pointable
    include Mixins::Callbacks

    alias ProxyType = LibGit::ProxyT

    def initialize(@raw : LibGit::ProxyOptions, @callbacks = Remotable::Callbacks.init); end

    def type=(t : ProxyType)
      to_unsafe.type = t
    end

    def url=(url)
      to_unsafe.url = url
    end

    define_callback credentials_acquire, Remotable::CredentialsAcquireCb, callbacks
    define_callback certificate_check, Remotable::CertificateCheckCb, callbacks

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
end
