module Grits
  module Cloning

    alias CheckoutProgressCb = (String, UInt64, UInt64 -> Void)

    alias CredentialsAcquireCb = (Credential -> Int32)
    alias FetchRemoteCbs = CredentialsAcquireCb

    class FetchOptionsCallbacksState
      getter :callbacks

      @on_credentials_acquire : CredentialsAcquireCb?

      def initialize
        @callbacks = [] of Symbol
      end

      def empty?
        @callbacks.empty?
      end

      def on_credentials_acquire(&block : CredentialsAcquireCb)
        @callbacks << :credential_acquire

        @on_credentials_acquire = block
      end

      def on_credentials_acquire
        @on_credentials_acquire
      end
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
    end

    class FetchOptions
      def initialize(@raw : LibGit::FetchOptions, @callbacks_state = FetchOptionsCallbacksState.new)
      end

      def on_credentials_acquire(&block : CredentialsAcquireCb)
        @callbacks_state.on_credentials_acquire(&block)
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
          when :credential_acquire
            @raw.callbacks.credentials = ->(credential_ptr : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt,  payload : Pointer(Void)) do
              callback = Box(FetchOptionsCallbacksState).unbox(payload).on_credentials_acquire
              resource = String.new(url)
              username = username_from_url.null? ? nil : String.new(username_from_url)
              credential = Credential.new(credential_ptr, url: resource, username: username)
              callback.try { |cb| cb.call(credential) } || 1
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
