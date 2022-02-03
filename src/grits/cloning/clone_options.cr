module Grits
  module Cloning

    alias CheckoutProgressCb = (String, UInt64, UInt64 -> Void)

    alias CredentialsAcquireCb = (Credential -> Int32)
    alias CertificateCheckCb = (LibGit::GitCert, String, Bool -> Bool?)

    class FetchOptionsCallbacksState
      getter :callbacks

      @on_credentials_acquire : CredentialsAcquireCb?

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
    end

    class Credential
      getter :url, :username, :raw

      def initialize(@raw : LibGit::Credential*, @url : String, @username : String?); end

      def add_ssh_key(*, username : String, public_key_path : String, private_key_path : String, passphrase : String? = nil)
        LibGit.credential_ssh_key_new(@raw, username, public_key_path, private_key_path, passphrase)
      end

      def add_ssh_key(*, username : String, public_key : String, private_key : String, passphrase : String? = nil)
        LibGit.credential_ssh_key_memory_new(@raw, username, public_key, private_key, passphrase)
      end

      def add_user_pass(*, username : String, password : String)
        LibGit.credential_userpass_plaintext_new(@raw, username, password)
      end

      def from_ssh_agent(*, username : String)
        LibGit.credential_ssh_key_from_agent(@raw, username)
      end
    end

    class FetchOptions
      def initialize(@raw : LibGit::FetchOptions, @callbacks_state = FetchOptionsCallbacksState.new)
      end

      def on_credentials_acquire(&block : CredentialsAcquireCb)
        @callbacks_state.on_credentials_acquire(&block)
      end

      def on_certificate_check(&block : CertificateCheckCb)
        @callbacks_state.on_certificate_check(&block)
      end

      def raw
        add_callbacks

        @raw
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
              value = callback.try { |cb| cb.call(cert.value, hostname, is_valid) }
              return 0 if value.nil?
              return value ? 1 : -1
            end
          end
        end
      end
    end

    class CheckoutOptions
      delegate(
        :version,
        :version=,
        :dir_mode,
        :dir_mode=,
        :file_mode,
        :file_mode=,
        :file_open_flags,
        :file_open_flags=,
        :notify_flags,
        :notify_flags=,
        :paths,
        :target_directory,
        :ancestor_label,
        :our_label,
        :their_label,
        to: @raw
      )

      def initialize(@raw : LibGit::CheckoutOptions)
      end

      def on_progress(&block : CheckoutProgressCb)
        @raw.progress_payload = Box.box(block)
        @raw.progress_cb = ->(path : LibC::Char*, completed_steps : LibC::SizeT, total_steps : LibC::SizeT, payload : Void*) do
          string_path = path.null? ? "(null)" : String.new(path)
          cb = Box(CheckoutProgressCb).unbox(payload)
          cb.call(string_path, completed_steps, total_steps)
        end
      end

      def raw
        @raw
      end
    end

    class CloneOptions
      def self.default
        Error.giterr LibGit.clone_options_init(out opts, LibGit::GIT_CLONE_OPTIONS_VERSION), "Can't create clone options"
        new opts
      end

      delegate(
        :version,
        :checkout_branch,
        :bare,
        to: @raw
      )

      def initialize(@raw : LibGit::CloneOptions)
        @checkout_options = CheckoutOptions.new(@raw.checkout_opts)
        @fetch_options = FetchOptions.new(@raw.fetch_opts)
      end

      def checkout_options
        @checkout_options
      end

      def fetch_options
        @fetch_options
      end

      def raw
        @raw.checkout_opts = checkout_options.raw
        @raw.fetch_opts = fetch_options.raw
        @raw
      end
    end
  end
end
