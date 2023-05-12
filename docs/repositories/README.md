# Repositories

The entrypoint for interacting with Grits is through [Grits::Repo][]

Most methods that return new git abstractions can be invoked with a block.
*Please use this interface.*  Block forms of methods will automatically free the object. 
If you don't do this, you'll need to call `#free` on objects manually.

!!! warning
    Manually managing objects may not be available in the future.

Example: [Grits::Repo#free][]

## Opening an existing repository

There are a few ways to open an existing repository.

* Open a repository -> [Grits::Repo.open][]
* Open a [bare repository](https://stackoverflow.com/questions/5540883/whats-the-practical-difference-between-a-bare-and-non-bare-repository) -> [Grits::Repo.open_bare][]
* Open a repository with [extended controls](https://libgit2.org/libgit2/#HEAD/group/repository/git_repository_open_ext) -> [Grits::Repo.open_ext][]

### Normally

```crystal
Grits::Repo.open("/path/to/repository") do |repo|
  # ... interact with repo
end
```

### Bare
```crystal
Grits::Repo.open_bare("/path/to/repository") do |repo|
  # ... try to interact with repo
end
```

### Extended

Opening a repository with extended controls provide more tuning than a normal open.
You can provide an Array of [Grits::OpenRepoType][] `flags` as well as a `GIT_PATH_LIST_SEPARATOR` delimited string of `ceiling_dirs` that define the upstream directories
at which the search for a containing repository should terminate.

!!! note
    According to libgit2.  `GIT_PATH_LIST_SEPARATOR` is `;` on Windows, and `:` on everything else.

#### Grits::OpenRepoType

`Grits::OpenRepoType::NoSearch`

:   Only open the repo if it can be immediately found in the path provided.
    Don't walk up parent directories to find the repository

`Grits::OpenRepoType::AcrossFs`

:   Unless this flag is set, open will not cross a filesystem boundary
    when searching.   

`Grits::OpenRepoType::Bare`

:   Open repository as a bare repo regardless of core.bare config, and
	  defer loading config file for faster setup.
	  
    Unlike [Grits::Repo.open_bare][], this can follow gitlinks.

`Grits::OpenRepoType::NoDotGit`

:   Do not check for a repository by appending /.git to the start_path;
	  only open the repository if start_path itself points to the git
	  directory.

`Grits::OpenRepoType::FromEnv`

:   Find and open a git repository, respecting the environment variables
	  used by the git command-line tools.

```crystal
# force the provided path to match the .git directory and don't search
# across a filesystem boundary
flags = [Grits::OpenRepoType::AcrossFs, Grits::OpenRepoType::NoDotGit]

# teriminate the search at `/home/skinnyjames`
ceilings = "/home/skinnyjames"

Grits::Repo.open_ext("/home/skinnyjames/src/grits/.git", flags: flags, ceiling_dirs: ceilings) do |repo|
  # ... interact with repo
end
```

## Initializing a new repository

There are a couple of ways to initialize a new repository.

* [Grits::Repo.init][]
* [Grits::Repo.init_ext][]

### Normal

```crystal
# create an empty folder with 755 permissions at /path/to/folder
Grits::Repo.init("/path/to/folder", make: true, mode: 0o755) do |repo|
  # ... interact
end
```

!!! note
    the `make` parameter defaults to `false`.  Don't include `make` and `mode` if
    the directory already exists.

### Extended

`Repo.init_ext` is the same as `Repo.init` except that it takes an additional `options` parameter.

`options` is a type of [Grits::RepoInitOptions][] and allows for configuring the remote origin, 
working directory, the initial name of `HEAD`, etc.

## Cloning a remote repository

There are a lot of ways to clone a repository.

Most of the configuration takes place in [Grits::CloneOptions][], and you can configure things like:

* Callbacks and options for fetching the remote, such as providing credentials or configuring a proxy.
* Callbacks and options for checking out the repo after download, such as only checking out specific paths or tracking progress

Lets dive in.

### Clone with default options

```crystal
# clone the remote to a local folder with default options
Grits::Repo.clone(
  "https://gitlab.com/skinnyjames/grits.git", 
  "/home/skinnyjames/local_grits"
) do |repo|
  # ... interact with repo
end
```

### Cloning with specific options (Grits::CloneOptions)

By default, `#clone` will use the default libgit2 clone options.

You can change this by providing a [Grits::CloneOptions][] parameter.
The easiest way to get this is to call `Grits::CloneOptions.default`

Example

```crystal
options = Grits::CloneOptions.default

# add a username/password for auth
options.fetch_options.on_credentials_acquire do |credential|
  credential.add_user_pass(
    username: "skinnyjames",
    password: ENV["SKINNYJAMES_ACCESS_TOKEN"]
  )
end

# add another remote
options.on_remote_create do |repo, name, url|
  Grits::Remote.create(
    repo, 
    "github", 
    "https://github.com/skinnyjames/grits-clone.git"
  ) 
end

# only checkout specific paths
options.checkout_options.paths = ["src", "spec"]

Grits::Repo.clone(
  "https://gitlab.com/skinnyjames/grits.git", 
  "/home/skinnyjames/grits", 
  options
) do |repo|
  # ... interact with repo
end
```

!!! info
    Many of the callbacks in Grits require a certain type of return value.
    For instance, [Grits::FetchOptions#on_certificate_check][] requires a return of `Bool`

    Returning `false` from this callback will cancel the clone.