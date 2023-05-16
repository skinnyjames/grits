# Staging changes

Staging changes are done by interacting with the index.

Grits provides [Grits::Repo#index][] to yield a [Grits::Index][] for interacting.

## Adding files

Adding files to the index can be done via

* [Grits::Index#add_file][]
* [Grits::Index#add_files][]

`Index#add_file` takes a single filename to add to the index.

For adding multiple files or directories, there is `Index#add_files`.  `#add_files` takes the following parameters:

* an array of paths or glob expressions to add
* an array of `Grits::IndexAddOption` flags to modify the add behavior.
* a notification callback that yields the matching file and path expression for every file to be added.

### Grits::IndexAddOption

[Grits::IndexAddOption][] is an enum with the following values.

`Grits::IndexAddOption::Default`

:   Default behavior

`Grits::IndexAddOption::Force`

:   Files that are ignored will be skipped. Provide this flag to skip checking of ignore rules.

`Grits::Index::AddOption::DisablePathspecMatch`

:   Disable glob expansion and force exact matching

`Grits::Index::AddOption::CheckPathspec`

:   Generates an an error if the pathspec contains the exact path of an ignored file.


!!! note
    When using [Grits::Index#add_files][], you must provide a block that takes 2 parameters and returns `Bool?`

    The parameters are 

    * the matched file
    * the pathspec responsible for the match

    Returning

    * `true` from the block will proceed with adding to the index
    * `false` from the block will cancel adding the file
    * `nil` from the block will abort the transaction

    ### Example

```crystal
repo_path = "/some/path"

Grits::Repo.init(repo_path) do |repo|
  File.write("#{repo_path}/top.txt", "content\n")

  repo.index do |stage|
    stage.add_files(["top"]) do |path, match|
      true
    end

    File.open("#{repo_path}/top", "a") { |io| io.print "more\n" }
  end
end
```

### Peristing changes to the index

When using `#add_files` or `#add_file` [Grits::Index#write]() will persist the index changes to disk.

There is also a method available that does both in one call. [Grits::Index.add][]

## Writing to a tree

In order to make a commit, the git index needs to be converted to a tree.

[Grits::Index.write_tree][] will write the contents of an index to a tree that is yielded to a block.

```crystal
#...
repo.index do |stage|
  stage.write_tree do |tree|
    # use tree to make a commit
  end
end
```

