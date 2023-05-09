@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  fun init = git_libgit2_init : LibC::Int
end
