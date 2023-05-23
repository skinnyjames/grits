@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  struct Oidarray
    ids : Oid*
    count : LibC::SizeT
  end

  fun oidarray_dispose = git_oidarray_dispose(array : Oidarray*) : Void
end