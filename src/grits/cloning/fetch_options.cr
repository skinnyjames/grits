module Grits
  module Cloning
    alias CredentialsAcquireCb = (Credential -> Int32)
    alias CertificateCheckCb = (Wrappers::Certificate, String, Bool -> Bool?)
    alias IndexerProgressCb = (Wrappers::IndexerProgress -> Bool?)

    struct FetchOptionsCallbacksState
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

    class FetchOptions
      include Mixins::Pointable
      include Mixins::Wrapper

      def initialize(@raw : LibGit::FetchOptions, @callbacks_state = FetchOptionsCallbacksState.new)
      end

      def on_credentials_acquire(&block : CredentialsAcquireCb)
        @callbacks_state.on_credentials_acquire(&block)
      end

      def on_certificate_check(&block : CertificateCheckCb)
        @callbacks_state.on_certificate_check(&block)
      end

      def on_transfer_progress(&block : IndexerProgressCb)
        @callbacks_state.on_transfer_progress(&block)
      end

      protected def computed_unsafe
        add_callbacks

        to_unsafe
      end

      private def add_callbacks
          return if @callbacks_state.empty?

        @raw.callbacks.payload = Box.box(@callbacks_state)

        @callbacks_state.callbacks.each do |cb|
          case cb
          when :credentials_acquire
            @raw.callbacks.credentials = ->(credential_ptr : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt,  payload : Pointer(Void)) do
              callback = Box(FetchOptionsCallbacksState).unbox(payload).on_credentials_acquire
              resource = String.new(url)
              username = username_from_url.null? ? nil : String.new(username_from_url)
              credential = Credential.new(credential_ptr, url: resource, username: username)
              callback.try { |cb| cb.call(credential) } || 1
            end
          when :certificate_check
            @raw.callbacks.certificate_check = ->(cert : LibGit::GitCert*, valid : LibC::Int, host : LibC::Char*, payload : Void*) do
              callback = Box(FetchOptionsCallbacksState).unbox(payload).on_certificate_check
              hostname = String.new(host)
              is_valid = valid == 1
              value = callback.try { |cb| cb.call(Wrappers::Certificate.new(cert), hostname, is_valid) }
                return 0 if value.nil?
              return value ? 1 : -1
            end
          when :transfer_progress
            @raw.callbacks.transfer_progress = ->(indexer : LibGit::IndexerProgress*, payload : Void*) do
              callback = Box(FetchOptionsCallbacksState).unbox(payload).on_transfer_progress
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