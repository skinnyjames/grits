# grits

[![Build Status](http://drone.skinnyjames.net/api/badges/seanchristophergregory/grits/status.svg)](http://drone.skinnyjames.net/seanchristophergregory/grits)

[api docs](https://seanchristophergregory.gitlab.io/grits/index.html)


Git library in progress for Crystal

Built over `libgit2` with the majority of the bindings borrowed from [smacker/libgit2.cr](https://github.com/smacker/libgit2.cr)

## why?

* I want to learn more about Crystal C interop
* I want to learn more about git

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     grits:
       gitlab: seanchristophergregory/grits
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
      
      Fixture.write_file("#{repo.workdir}/something.text", "Hello World")
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

## Contributing

1. Fork it (<https://gitlab.com/seanchristophergregory/grits/-/forks/new>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Merge Request

## Contributors

- [Sean Gregory](https://gitlab.com/seanchristohpergregory) - creator and maintainer
