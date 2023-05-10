module Grits
  alias DiffFileCb = (Grits::DiffDelta, Float64 ->)
  alias DiffBinaryCb = (Grits::DiffDelta, Grits::DiffBinary ->)
  alias DiffHunkCb = (Grits::DiffDelta, Grits::DiffHunk ->)
  alias DiffLineCb = (Grits::DiffDelta, Grits::DiffHunk, Grits::DiffLine ->)

  class DiffForeachCallbacks < CallbacksState
    define_callback DiffFileCb, file
    define_callback DiffBinaryCb, binary
    define_callback DiffHunkCb, hunk
    define_callback DiffLineCb, line
  end

  struct DiffIterator
    include Mixins::Callbacks
    
    @callbacks_state = DiffForeachCallbacks.new

    @file_cb : LibGit::DiffFileCb = -> (delta : LibGit::DiffDelta*, progress : LibC::Float, payload : Void*) {0}
    @binary_cb : LibGit::DiffBinaryCb = -> (delta : LibGit::DiffDelta*, binary : LibGit::DiffBinary*, payload : Void*) {0}
    @hunk_cb : LibGit::DiffHunkCb = -> (delta : LibGit::DiffDelta*, hunk : LibGit::DiffHunk*, payload : Void*) {0}
    @line_cb : LibGit::DiffLineCb = -> (delta : LibGit::DiffDelta*, hunk : LibGit::DiffHunk*, line : LibGit::DiffLine*, payload : Void*) {0}

    define_callback file, DiffFileCb, callbacks_state
    define_callback binary, DiffBinaryCb, callbacks_state
    define_callback hunk, DiffHunkCb, callbacks_state
    define_callback line, DiffLineCb, callbacks_state

    def execute(diff : Grits::Diff)
      payload = Box(DiffForeachCallbacks).box(@callbacks_state)

      add_callbacks

      Error.giterr LibGit.diff_foreach(diff.to_unsafe, @file_cb, @binary_cb, @hunk_cb, @line_cb, payload), "Could not iterate diffs"
    end

    def add_callbacks
      @callbacks_state.callbacks.each do |cb|
        case cb
        when :file
          @file_cb = ->(delta : LibGit::DiffDelta*, progress : LibC::Float, payload : Void*) do
            if callback = Box(DiffForeachCallbacks).unbox(payload).on_file
              wrapped_delta = Grits::DiffDelta.new(delta)
              progress = Float64.new(progress)

              callback.call(wrapped_delta, progress)
            end
            
            0
          end
        when :binary
          @binary_cb = ->(delta : LibGit::DiffDelta*, binary : LibGit::DiffBinary*, payload : Void*) do
            
            if callback = Box(DiffForeachCallbacks).unbox(payload).on_binary
              wrapped_delta = Grits::DiffDelta.new(delta)
              wrapped_binary = Grits::DiffBinary.new(binary)

              callback.call(wrapped_delta, wrapped_binary)
            end
            
            0
          end
        when :hunk
          @hunk_cb = ->(delta : LibGit::DiffDelta*, hunk : LibGit::DiffHunk*, payload : Void*) do
            if callback = Box(DiffForeachCallbacks).unbox(payload).on_hunk
              wrapped_delta = Grits::DiffDelta.new(delta)
              wrapped_hunk = Grits::DiffHunk.new(hunk)

              callback.call(wrapped_delta, wrapped_hunk)
            end
            
            0
          end
        when :line
          @line_cb = -> (delta : LibGit::DiffDelta*, hunk : LibGit::DiffHunk*, line : LibGit::DiffLine*, payload : Void*) do
            if callback = Box(DiffForeachCallbacks).unbox(payload).on_line
              wrapped_delta = Grits::DiffDelta.new(delta)
              wrapped_hunk = Grits::DiffHunk.new(hunk)
              wrapped_line = Grits::DiffLine.new(line)

              callback.call(wrapped_delta, wrapped_hunk, wrapped_line)
            end

            0
          end
        end
      end
    end
  end
end