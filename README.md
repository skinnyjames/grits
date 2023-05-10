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

# clone via ssh, add and commit a file

options = Grits::CloneOptions.default
options.fetch_options.on_credentials_acquire do |credential|
   credential.add_ssh_key(
      username: credential.username || "git",
      public_key: ENV["PUBLIC_KEY"],
      private_key: ENV["PRIVATE_KEY"],
   )
end

Grits::Repo.clone("git@gitlab.com:seanchristophergregory/grits.git", "./local_grits_dir", options) do |repo|
   repo.index do |index|
      author = { email: "sean@sean.com", name: "Sean Gregory", time: Time.utc }
      committer = author

      File.open("#{repo.workdir}something.text", "w") { |f| f << "hello world!" }
      index.add "something.text"

      Grits::Commit.create(repo,
         author: author,
         message: "Hello World",
         committer: committer,
         parents: [repo.last_commit.sha],
         tree: index.tree,
         update_ref: "HEAD"
      ) do |commit|
         puts commit.message
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
