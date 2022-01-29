module Grits
  module Cloning

    alias CheckoutProgressCb = (String, UInt64, UInt64 -> Void)

    alias CredentialsAcquireCb = (Pointer(LibGit::Credential), String, String? -> Int32)
    alias FetchRemoteCbs = CredentialsAcquireCb

    class Cbs
      @@box : Pointer(Void)?

      def initialize(@state = {} of String => Pointer(Void)); end

      def any?
        @state.keys.size > 0
      end

      def keys
        @state.keys
      end

      def add(name : String, cb : CredentialsAcquireCb)
        @state[name] = cb
      end

      def get(name : String)
        @state[name]
      end
    end

    class FetchOptions

      def self.init
        options = LibGit::FetchOptions.new
        Error.giterr LibGit.fetch_options_init(pointerof(options), LibGit::GIT_CLONE_OPTIONS_VERSION), "Couldn't init fetch options"
        new(options)
      end

      delegate(
        :version,
        :version=,
        :update_fetchhead,
        :update_fetchhead=,
        to: @raw
      )

      @box : Pointer(Void)?

      def initialize(@raw : LibGit::FetchOptions)
      end

      def on_credentials_acquire(&block : CredentialsAcquireCb)
        callbacks = @raw.callbacks
        @box = Box.box("hello")
        # this breaks
        @box.try { |box| callbacks.payload = box }
        callbacks.credentials = ->(credential : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt, payload : Void*) do
          #callback = Box(FetchRemoteCbs).unbox(payload)
          resource = String.new(url)
          username = username_from_url.null? ? nil : String.new(username_from_url)
          puts username, resource, credential.value
          #callback.call(credential, resource, username)
          credential.value
        end
        @raw.callbacks = callbacks
      end

      def raw
        @raw
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
        Error.giterr LibGit.clone_options_init(out options, LibGit::GIT_CLONE_OPTIONS_VERSION), "Can't create clone options"
        new(options)
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
