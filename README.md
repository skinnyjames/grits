# grits [![status-badge](https://ci.skinnyjames.net/api/badges/skinnyjames/grits/status.svg)](https://ci.skinnyjames.net/skinnyjames/grits)

Git library in progress for Crystal | [Documentation](https://skinnyjames.codeberg.page/grits/)

## Requirements

This library downloads and installs a specific version of libgit2 into `grits/vendor`.  The supported version is currently 1.3.0.

In order to do this, you will need to have [xmake](https://xmake.io/#/) installed on your system.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     grits:
       git: https://codeberg.org/skinnyjames/grits.git
   ```

2. Run `shards install`

## Usage

```crystal
require "grits"

dest = "#{__DIR__}/some_folder"

Grits::Repo.clone(
  "https://codeberg.org/skinnyjames/grits.git", 
  dest, 
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

## Development

To run the gitea test fixture

`docker run -p 3000:3000 -p 222:22 skinnyjames/grits-gitea-fixture:latest`

then

`crystal spec`

### Manual validation

Navigate to `http://127.0.0.1:3000`

Login with `skinnyjames` / `password`

## Contributors

- [Sean Gregory](https://codeberg.org/skinnyjames) - creator and maintainer

## Thanks

Thanks to [smacker](https://github.com/smacker) for initial work on [smacker/libgit2.cr](https://github.com/smacker/libgit2.cr)
