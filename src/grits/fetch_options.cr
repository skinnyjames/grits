module Grits
  struct FetchOptions
    include Mixins::Pointable
    include Mixins::Wrapper
    include Mixins::Callbacks

    @callbacks : Grits::Remote::Callbacks

    def initialize(@raw : LibGit::FetchOptions)
      @callbacks = Remote::Callbacks.new to_unsafe.callbacks
    end

    define_callback credentials_acquire, Remote::CredentialsAcquireCb, callbacks
    define_callback certificate_check, Remote::CertificateCheckCb, callbacks
    define_callback transfer_progress, Remote::IndexerProgressCb, callbacks

    protected def computed_unsafe
      to_unsafe.callbacks = @callbacks.computed_unsafe

      to_unsafe
    end
  end
end