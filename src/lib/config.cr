@[Link(ldflags: "-l:libgit2.so.1.3")]
lib LibGit
  type Config = Void*

  fun config_set_bool = git_config_set_bool(config : Config, name : LibC::Char*, value : LibC::Int) : LibC::Int
  fun config_get_bool = git_config_get_bool(out : LibC::Int*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_free = git_config_free(config : Config) : Void
end
