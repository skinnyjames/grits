### this project has moved to to [GitLab](https://gitlab.com/seanchristophergregory/grits)

# grits

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

# see specs
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
