module Grits
  module Cloning

    alias CheckoutProgressCb = (String, UInt64, UInt64 -> Void)

    alias CredentialsAcquireCb = (LibGit::Credential, String, String? -> Int32)
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
      def initialize
      end

      def on_credentials_acquire(&block : CredentialsAcquireCb)
        @on_credentials_acquire = block


        # #@raw.callbacks.payload = Box.box("hello")
        # @raw.callbacks.credentials = ->(credential : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt,  hello : Pointer(Void)) do
        #   #callback = Box(FetchRemoteCbs).unbox(payload)
        #   resource = String.new(url)
        #   username = username_from_url.null? ? nil : String.new(username_from_url)
        #   puts username, resource, credential.value
        #   puts allowed_types
        #   #callback.call(credential, resource, username)
        #   credential.value
        # end
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
        puts "progress #{@raw.progress_payload}"
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
        @fetch_options = FetchOptions.new
        @toggle = false
      end

      def checkout_options
        @checkout_options
      end

      def fetch_options
        @fetch_options
      end

      def toggle
        @toggle = true
        @box = Box.box(@fetch_options)
        puts @raw.fetch_opts.callbacks.payload
        @box.try { |b| @raw.fetch_opts.callbacks.payload = b }
        @raw.fetch_opts.callbacks.credentials = ->(credential : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt,  hello : Void*) do
          #callback = Box(FetchRemoteCbs).unbox(payload)
          resource = String.new(url)
          username = username_from_url.null? ? nil : String.new(username_from_url)
          puts username, resource, credential.value
          puts allowed_types
          #callback.call(credential, resource, username)
          credential.value
        end
        #@raw.checkout_opts = checkout_options.raw
        @raw.remote_cb_payload = Box.box("hello")
      end

      def init_clone_opts
        Error.giterr LibGit.clone_options_init(out options, LibGit::GIT_CLONE_OPTIONS_VERSION), "Can't create clone options"
        options
      end

      def init_proxy_opts
        Error.giterr LibGit.proxy_options_init(out options, 1), "Stuff"
        options
      end

      def init_callbacks
        Error.giterr LibGit.remote_init_callbacks(out opts, LibGit::REMOTE_CALLBACKS_VERSION), "bad"
        opts
      end

      def init_fetch_opts
        Error.giterr LibGit.fetch_options_init(out options, 1), "Stuff"
        options
      end

      def raw
        clone_opts = init_clone_opts
        callbacks = init_callbacks

        callbacks.payload = Box(String).box("y") # this line crashes
        callbacks.credentials = ->(credential : LibGit::Credential*, url : LibC::Char*, username_from_url : LibC::Char*, allowed_types : LibC::UInt,  payload : Void*) do
          puts url, Box(String).unbox(payload)
          credential
          1
        end

        callbacks.remote_ready = ->(remote : LibGit::Remote, int : LibC::Int, payload : Void*) do
          puts "remote", Box(String).unbox(payload)
          1
        end
        clone_opts.checkout_opts.progress_payload = Box.box("hello")
        clone_opts.checkout_opts.progress_cb = ->(path : LibC::Char*, completed_steps : LibC::SizeT, total_steps : LibC::SizeT, payload : Void*) do
          puts Box(String).unbox(payload)
        end
        clone_opts.fetch_opts.callbacks = callbacks
        clone_opts
      end
    end
  end
end
