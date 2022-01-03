module Grits
  module Cloning

    alias CheckoutProgressCb = (String, UInt64, UInt64 -> Void)

    class CheckoutOptions
      delegate(
        :version,
        :dir_mode,
        :file_mode,
        :file_open_flags,
        :notify_flags,
        :paths,
        :target_directory,
        :ancestor_label,
        :our_label,
        :their_label,
        to: @raw
      )

      def initialize(@raw : Pointer(LibGit::CheckoutOptions))
      end

      def on_progress(&block : CheckoutProgressCb)
        @raw.value.progress_payload = Box.box(block)
        @raw.value.progress_cb = ->(path : LibC::Char*, completed_steps : LibC::SizeT, total_steps : LibC::SizeT, payload : Void*) do
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
        checkout_opts = raw.checkout_opts
        @checkout_options = CheckoutOptions.new(pointerof(checkout_opts))
      end

      def checkout_options
        @checkout_options
      end

      def raw
        @raw.checkout_opts = checkout_options.raw.value
        @raw
      end
    end
  end
end
