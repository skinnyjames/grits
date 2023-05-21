module Grits
  module Remotable
    include Mixins::Pointable

    alias CredentialsAcquireCb = (Credential -> Int32)
    alias CertificateCheckCb = (Wrappers::Certificate, String, Bool -> Bool?)
    alias IndexerProgressCb = (Wrappers::IndexerProgress -> Bool?)
    # these may return things that affect the remotable instead of Void (no docs)
    alias UpdateTipsCb = (String, Oid, Oid -> Void)
    alias PackBuilderProgressCb = (Int32, UInt32, UInt32 -> Void)
    alias PushTransferProgressCb = (UInt32, UInt32, LibC::SizeT -> Void)
    alias PushUpdateReferenceCb = (String, String -> Bool?)
    alias PushNegotiation = (Wrappers::PushUpdate, LibC::SizeT -> Void)
    alias ResolveUrlCb = (UrlResolver -> Int32?)
    alias TransportCb = (Transport -> Bool)

    struct UrlResolver
      def initialize(@buffer : LibGit::Buf*, @url : LibC::Char*, @direction : LibC::Int); end

      def url
        String.new(@url)
      end

      def direction
        @direction == 0 ? :fetch : :push
      end

      def push?
        direction == :push
      end

      def fetch?
        direction == :fetch
      end

      def set(new_url : String)
        LibGit.buf_set(@buffer, new_url, new_url.size)
      end
    end

    class CallbacksState < Grits::CallbacksState
      define_callback CertificateCheckCb, certificate_check
      define_callback CredentialsAcquireCb, credentials_acquire
      define_callback IndexerProgressCb, transfer_progress
      define_callback UpdateTipsCb, update_tips
      define_callback PackBuilderProgressCb, pack_progress
      define_callback PushTransferProgressCb, push_progress
      define_callback PushUpdateReferenceCb, push_update_reference
      define_callback PushNegotiation, push_negotiation
      define_callback ResolveUrlCb, resolve_url
      define_callback TransportCb, transport
    end

    struct Callbacks
      include Mixins::Pointable
      include Mixins::Callbacks

      def self.init
        Error.giterr LibGit.remote_init_callbacks(out cbs, 1), "Can't init remote callbacks"
        new(cbs)
      end

      def initialize(@raw : LibGit::RemoteCallbacks, @callbacks_state = CallbacksState.new); end

      define_callback credentials_acquire, CredentialsAcquireCb, callbacks_state
      define_callback certificate_check, CertificateCheckCb, callbacks_state
      define_callback transfer_progress, IndexerProgressCb, callbacks_state
      define_callback update_tips, UpdateTipsCb, callbacks_state
      define_callback pack_progress, PackBuilderProgressCb, callbacks_state
      define_callback push_progress, PushTransferProgressCb, callbacks_state
      define_callback push_update_reference, PushUpdateReferenceCb, callbacks_state
      define_callback push_negotiation, PushNegotiation, callbacks_state
      define_callback resolve_url, ResolveUrlCb, callbacks_state
      define_callback transport, TransportCb, callbacks_state

      def empty?
        @callbacks_state.empty?
      end

      protected def computed_unsafe
        add_callbacks

        to_unsafe
      end

      protected def add_callbacks
        return if empty?

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
          when :update_tips
            @raw.update_tips = ->(word : LibC::Char*, oid : LibGit::Oid*, oid_2 : LibGit::Oid*, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_update_tips
              callback.try { |cb| cb.call(String.new(word), Oid.new(oid.value), Oid.new(oid_2.value)) }
              0
            end
          when :pack_progress
            @raw.pack_progress = ->(stage : LibC::Int, current : LibC::UInt32T, total : LibC::UInt32T, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_pack_progress
              callback.try do |cb|
                cb.call(stage.to_i32, current.to_u32, total.to_u32)
              end
              0
            end
          when :push_progress
            @raw.push_transfer_progress = ->(current : LibC::UInt, total : LibC::UInt, bytes : LibC::SizeT, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_push_progress
              callback.try do |cb|
                cb.call(current.to_u32, total.to_u32, bytes)
              end
              0
            end
          when :push_update_reference
            @raw.push_update_reference = ->(refname : LibC::Char*, status : LibC::Char*, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_push_update_reference
              res = callback.try { |cb| cb.call(String.new(refname), String.new(status)) }
              return 1 if res == false
              0
            end
          when :push_negotiation
            @raw.push_negotiation = ->(updates : LibGit::PushUpdate**, length : LibC::SizeT, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_push_negotiation
              update = Wrappers::PushUpdate.new(updates.value)
              callback.try { |cb| cb.call(update, length) }
              0
            end
          when :resolve_url
            @raw.resolve_url = ->(buffer : LibGit::Buf*, url : LibC::Char*, direction : LibC::Int, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_resolve_url
              resolver = UrlResolver.new(buffer, url, direction)
              ret = callback.try { |cb| cb.call(resolver) }
              ret.nil? ? LibGit::ErrorCode::Passthrough.to_i32 : ret
            end
          when :transport
            @raw.transport = ->(transport : LibGit::Transport*, remote : LibGit::Remote, payload : Void*) do
              callback = Box(CallbacksState).unbox(payload).on_transport
              remoter = Grits::Remote.new(remote)
              transporter = Grits::Transport.new(remoter, transport.value)

              ret = callback.try { |cb| cb.call(transporter) }
              ret ? 0 : 1
            end
          end
        end
      end
    end
  end
end