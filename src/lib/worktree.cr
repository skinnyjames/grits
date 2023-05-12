@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  type Worktree = Void*

  fun worktree_open_from_repository = git_worktree_open_from_repository(worktree : Worktree*, repo : Repository) : LibC::Int
  fun worktree_free = git_worktree_free(worktree : Worktree)
  fun worktree_validate = git_worktree_validate(worktree : Worktree) : LibC::Int
end