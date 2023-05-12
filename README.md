# grits

[![Build Status](http://drone.skinnyjames.net/api/badges/skinnyjames/grits/status.svg)](http://drone.skinnyjames.net/skinnyjames/grits)

[api docs](https://skinnyjames.gitlab.io/grits/index.html)


Git library in progress for Crystal

Note: these bindings are currently locked for `libgit2.so.1.3` to preserve compatibility.

## why?

* I want to learn more about Crystal C interop
* I want to learn more about git

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     grits:
       gitlab: skinnyjames/grits
   ```

2. Run `shards install`

## Usage

```crystal
require "grits"

dest = "#{__DIR__}/some_folder"

Grits::Repo.clone(
  "https://gitlab.com/skinnyjames/grits.git", 
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

## Contributing

1. Fork it (<https://gitlab.com/skinnyjames/grits/-/forks/new>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Merge Request

## Contributors

- [Sean Gregory](https://gitlab.com/skinnyjames) - creator and maintainer

## Thanks

Thanks to [smacker](https://github.com/smacker) for initial work on [smacker/libgit2.cr](https://github.com/smacker/libgit2.cr)
