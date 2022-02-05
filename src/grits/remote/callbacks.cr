module Grits
  module Remote
    include Mixins::Pointable

    alias CredentialsAcquireCb = (Credential -> Int32)
    alias CertificateCheckCb = (Wrappers::Certificate, String, Bool -> Bool?)
    alias IndexerProgressCb = (Wrappers::IndexerProgress -> Bool?)

    struct CallbacksState
      getter :callbacks

      macro define_callback(type, key)
        def on_{{ key }}(&block : {{ type }})
          @callbacks <<  :{{ key }}

          @on_{{ key }} = block
        end

        def on_{{ key }}
          @on_{{ key }}
        end
      end

      def initialize
        @callbacks = [] of Symbol
      end

      def empty?
        @callbacks.empty?
      end

      define_callback CertificateCheckCb, certificate_check
      define_callback CredentialsAcquireCb, credentials_acquire
      define_callback IndexerProgressCb, transfer_progress
    end

    struct Callbacks
      include Mixins::Pointable
      include Mixins::Callbacks

      def initialize(@raw : LibGit::RemoteCallbacks, @callbacks_state = CallbacksState.new); end

      define_callback credentials_acquire, CredentialsAcquireCb, callbacks_state
      define_callback certificate_check, CertificateCheckCb, callbacks_state
      define_callback transfer_progress, IndexerProgressCb, callbacks_state

      protected def computed_unsafe
        add_callbacks

        to_unsafe
      end

      protected def add_callbacks
        return if @callbacks_state.empty?

        @raw.payload = Box.box(@callbacks_state)

        @callbacks_state.callbacks.each do |cb|
          case cb
          when :credentials_acquire
            @raw.credentials = ->(credential_ptr : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt,  payload : Pointer(Void)) do
              callback = Box(CallbacksState).unbox(payload).on_credentials_acquire
              resource = String.new(url)
              username = username_from_url.null? ? nil : String.new(username_from_url)
              credential = Credential.new(credential_ptr, url: resource, username: username)
              callback.try { |cb| cb.call(credential) } || 1
            end
          when :certificate_check
            @raw.certificate_check = ->(cert : LibGit::GitCert*, valid : LibC::Int, host : LibC::Char*, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_certificate_check
              hostname = String.new(host)
              is_valid = valid == 1
              value = callback.try { |cb| cb.call(Wrappers::Certificate.new(cert), hostname, is_valid) }
                return 0 if value.nil?
              return value ? 1 : -1
            end
          when :transfer_progress
            @raw.transfer_progress = ->(indexer : LibGit::IndexerProgress*, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_transfer_progress
              indexer_progress = Wrappers::IndexerProgress.new(indexer)
              value = callback.try { |cb| cb.call(indexer_progress) }
              return value.nil? ? 0 : value ? 0 : -1
            end
          end
        end
      end
    end
  end
end