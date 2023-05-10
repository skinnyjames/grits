module Grits
  # @param <Diff> the diff in progress
  # @param <DiffDelta> the delta to add
  # @param <String> the matched pathspec
  # @return <DiffNotifyResult> Abort | Continue | Skip
  alias DiffOptionsNotifyCb = (Grits::Diff, Grits::DiffDelta, String -> DiffNotifyResult)

  # @param <Diff> the diff in progress
  # @param <String> path to old file or nil
  # @param <String> path to new file or nil
  # @return <Bool> abort the diff?
  alias DiffOptionsProgressCb = (Grits::Diff, String?, String? -> Bool)
  
  enum DiffNotifyResult
    Abort = -1
    Continue = 0
    Skip = 1
  end

  class DiffOptionsCallbacks < CallbacksState
    define_callback DiffOptionsNotifyCb, notify
    define_callback DiffOptionsProgressCb, progress
  end
end
