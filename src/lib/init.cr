{% if flag?(:darwin) %}
@[Link("git2.1.3")]
{% else %}
@[Link(ldflags: "-l:libgit2.so.1.3")]
{% end %}
lib LibGit
  fun init = git_libgit2_init : LibC::Int
end
