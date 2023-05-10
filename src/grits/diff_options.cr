require "./callbacks/diff_options_callbacks"

module Grits
  struct DiffOptions
    alias Type = LibGit::DiffOptionT
    alias SubmoduleIgnore = LibGit::SubmoduleIgnoreT

    @callbacks_state : DiffOptionsCallbacks = DiffOptionsCallbacks.new
    @flags = [] of Type

    include Mixins::Pointable
    include Mixins::Wrapper
    include Mixins::Callbacks

    define_callback notify, DiffOptionsNotifyCb, callbacks_state
    define_callback progress, DiffOptionsProgressCb, callbacks_state
        
    def self.default : DiffOptions
      raw = LibGit::DiffOptions.new
      Error.giterr(LibGit.diff_options_init(pointerof(raw), LibGit::DIFF_OPTIONS_VERSION), "Could not init diff options")
      new(raw)
    end

    def initialize(@raw : LibGit::DiffOptions); end

    macro add_flag_method(method, type)
      def {{method.id}} : Nil
        @flags << Type::{{type.id}}
      end
    end

    add_flag_method(normal, Normal)
    add_flag_method(reverse, Reverse)
    add_flag_method(include_ignored, IncludeIgnored)
    add_flag_method(recurse_ignored_dirs, RecurseIgnoredDirs)
    add_flag_method(include_untracked, IncludeUntracked)
    add_flag_method(include_typechange, IncludeTypechange)
    add_flag_method(include_typechange_trees, IncludeTypechangeTrees)
    add_flag_method(ignore_filemode, IgnoreFilemode)
    add_flag_method(use_ignore_submodules, IgnoreSubmodules)
    add_flag_method(ignore_case, IgnoreCase)
    add_flag_method(ignore_case_change, IgnoreCasechange)
    add_flag_method(disable_pathspec_match, DisablePathspecMatch)
    add_flag_method(skip_binary_check, SkipBinaryCheck)
    add_flag_method(enable_fast_untracked_dirs, EnableFastUntrackedDirs)
    add_flag_method(update_index, UpdateIndex)
    add_flag_method(include_unreadable, IncludeUnreadable)
    add_flag_method(include_unreadable_as_untracked, IncludeUnreadableAsUntracked)
    add_flag_method(indent_heuristic, IndentHeuristic)
    add_flag_method(ignore_blank_lines, IgnoreBlankLines)
    add_flag_method(force_text, ForceText)
    add_flag_method(force_binary, ForceBinary)
    add_flag_method(ignore_whitespace, IgnoreWhitespace)
    add_flag_method(ignore_whitespace_change, IgnoreWhitespaceChange)
    add_flag_method(ignore_whitespace_eol, IgnoreWhitespaceEol)
    add_flag_method(show_untracked_content, ShowUntrackedContent)
    add_flag_method(show_unmodified, ShowUnmodified)
    add_flag_method(patience, Patience)
    add_flag_method(minimal, Minimal)
    add_flag_method(show_binary, ShowBinary)

    def flags=(flags : Array(Type))
      @flags = flags
    end

    def computed_unsafe_ptr
      unsafe = computed_unsafe

      pointerof(unsafe)
    end

    def computed_unsafe      
      add_callbacks

      unsafe = to_unsafe

      unless @flags.empty?
        unsafe.flags = @flags.map(&.value).reduce do |memo, val|
          memo | val
        end
      end

      unsafe
    end

    def ignore_submodules=(val : SubmoduleIgnore)
      to_unsafe.ignore_submodules = val
    end
    wrap_value @raw, ignore_submodules

    def pathspec=(paths : Array(String))
      to_unsafe.pathspec = convert_to_strarray(paths)
    end

    wrap_value raw, context_lines, true
    wrap_value raw, interhunk_lines, true
    wrap_value raw, id_abbrev, true

    def max_size=(size : Int64)
      @raw.max_size = size
    end

    wrap_value @raw, max_size

    def old_prefix=(val)
      @raw.old_prefix = val
    end

    def old_prefix : String
      String.new(@raw.old_prefix)
    end

    def new_prefix=(val)
      @raw.new_prefix = val
    end

    def new_prefix : String
      String.new(@raw.new_prefix)
    end

    protected def add_callbacks
      @raw.payload = Box(DiffOptionsCallbacks).box(@callbacks_state)

      @callbacks_state.callbacks.each do |cb|
        case cb
        when :notify
          @raw.notify_cb = -> (diff : LibGit::Diff, delta : LibGit::DiffDelta*, pathspec : LibC::Char*, payload : Void*) do
            if callback = Box(DiffOptionsCallbacks).unbox(payload).on_notify
              wrapped_diff = Grits::Diff.new(diff)
              wrapped_delta = Grits::DiffDelta.new(delta)
              wrapped_pathspec = String.new(pathspec)
              callback.call(wrapped_diff, wrapped_delta, wrapped_pathspec)
            end
            0
          end
        when :progress
          @raw.progress_cb = -> (diffptr : LibGit::Diff, old_path : LibC::Char*, new_path : LibC::Char*, payload : Void*) do
            if callback = Box(DiffOptionsCallbacks).unbox(payload).on_progress
              wrapped_diff = Grits::Diff.new(diffptr)
              wrapped_old_path = old_path.null? ? nil : String.new(old_path)
              wrapped_new_path = new_path.null? ? nil :  String.new(new_path)

              callback.call(wrapped_diff, wrapped_old_path, wrapped_new_path) ? 0 : -1
            end
            0
          end
        end
      end
    end
  end
end
