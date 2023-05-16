# Introduction

A Crystal library for programatic git interactions.  Built over [libgit2](https://libgit2.org/).

## Installation

### libgit2

Grits depends on `libgit2`, specifically `libgit2.so.1.3`.  

This is done to ensure compatibility with libgit2.  
The easiest method is probably a build from the [libgit2 v1.3.2](https://github.com/libgit2/libgit2/releases/tag/v1.3.2) release

See the [libgit2 quick start](https://github.com/libgit2/libgit2#quick-start) for installation steps.

!!! note
    If you want [support for the SSH transport](https://github.com/libgit2/libgit2#optional-dependencies), please make sure `LIBSSH2` is present when installing libgit2.

### Grits

In your `shard.yml`

```
dependencies:
  grits:
    gitlab: skinnyjames/grits
```

and run `shards install`

## Usage

Grits exposes a friendly interface for interacting with git abstractions.

The primary entrypoint is [Grits::Repo][], but the aim of this shard is to support all libgit2 behaviors.

For instance, interactive with a private remote repository using an ssh key looks like

```crystal
require "grits"

# create a new clone options
options = Grits::CloneOptions.default

# define an `on_credentials_acquire` callback
options.fetch_options.on_credentials_acquire do |credential|
  credential.add_ssh_key(
    username: credential.username || "git",
    public_key_path: "/path/to/id_rsa.pub",
    private_key_path: "/path/to/id_rsa",
  )
end

dest = "#{__DIR__}/some_folder"

Grits::Repo.clone(
  "git@gitlab.com:<username>/<private_repo>.git", 
  destination, 
  options
) do |repo|
  # interact with the repo..
  # create a new untracked file
  File.write("#{dest}/new.txt", "Hello Grits.\n")

  repo.index do |stage|
    # add the new file to the staging index
    stage.add("new.txt")

    File.open("#{path}/new.txt", "a") do |io|
      io.print "Goodbye.\n"
    end

    # diff the changes
    stage.diff_workdir do |diff|
      changes = diff.lines.map { |line| { line.hunk.header, line.content } }
      puts changes # => [{"@@ -1 +1,2 @@\n", "Hello Grits.\n"}, {"@@ -1 +1,2 @@\n", "Goodbye.\n"}]
    end

    # Write the index to a tree and yield it for commit
    stage.write_tree do |tree|
      repo.commit_at("HEAD") do |parent|
        committer = author = { 
          email: "sean@skinnyjames.net", 
          name: "Sean Gregory", 
          time: Time.utc 
        }

        tree.commit(
          author: author,
          message: "Hello World",
          committer: committer,
          parents: [parent],
          update_ref: "HEAD"
        ) do |commit|
          puts commit.message # => "Hello World"
        end
      end
    end
  end
end
```