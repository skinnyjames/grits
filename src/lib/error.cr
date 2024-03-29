{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  enum ErrorCode
    Ok             =   0
    Error          =  -1
    NotFound       =  -3
    Exists         =  -4
    Ambiguous      =  -5
    Bufs           =  -6
    User           =  -7
    BareRepo       =  -8
    UnbornBranch   =  -9
    Unmerged       = -10
    NonFastForward = -11
    InvalidSpec    = -12
    Conflict       = -13
    Locked         = -14
    Modified       = -15
    Auth           = -16
    Certificate    = -17
    Applied        = -18
    Peel           = -19
    Eof            = -20
    Invalid        = -21
    Uncommitted    = -22
    Directory      = -23
    MergeConflict  = -24
    Passthrough    = -30
    Iterover       = -31
    Retry          = -32
    Mismatch       = -33
    EIndexDirty    = -34
    EApplyFail     = -35
  end

  struct Error
    message : LibC::Char*
    klass : LibC::Int
  end

  fun error_last = git_error_last : Error*
  fun err_last = giterr_last : Error
  fun err_clear = giterr_clear
end
