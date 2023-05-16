# Diffing changes

From the [docs](A diff represents the cumulative list of differences between two snapshots of a repository (possibly filtered by a set of file name patterns).)

> A diff represents the cumulative list of differences between two snapshots of a repository (possibly filtered by a set of file name patterns).

## Grits::Diff

Various methods and callbacks yield a [Grits::Diff][].  Methods are exposed on a diff to compare differences on the level of 

* `Delta`: An encapsulation of the diff between 2 files ([Grits::DiffDelta][])
* `File`: An oject representing a diffed file ([Grits::DiffFile][])
* `Hunk`: A span of modified lines in a delta with context. ([Grits::DiffHunk][])
* `Line`: A range of characters inside a `Hunk` ([Grits::DiffLine][])

## Grits::DiffIterator

It is possible to setup an object to traverse the components of a diff.  This is done with [Grits::DiffIterator][]

`DiffIterator` has event driven callbacks that are triggered by the traversal, and yield different parts of the diff to each one.

```crystal
# assuming a variable `some_diff` is a `Grits::Diff`

diff_iterator = Grits::DiffIterator.new

diff_iterator.on_file do |file|
  # interact with file
end

diff_iterator.on_hunk do |hunk|
  # interact with hunk
end

diff_iterator.on_line do |line|
  # interact with the line
end

diff_iterator.execute(some_diff)
```

!!! warning

    The diff objects that are yielded to iterator methods will automatically be freed after the block ends.

    This means that the objects **cannot** be used outside of their respective blocks.

    Each diff object should have a `#data` method to return a copy of that object's values.  Ex: ([Grits::LineData][])

    [Grits::Diff][] automatically captures these datapoints with [Grits::Diff#files][], [Grits::Diff#hunks][], and [Grits::Diff#lines][]

## Providing options

Methods that return a `Grits::Diff` may take a [Grits::DiffOptions][].  

The options can be configured to accomodate various intentions, such as adding context to the diff, ignoring file modes or blank lines, or providing an array of paths to seach against.

The options also have callbacks to be notified of the diff progress and right before the delta is inserted into the diff.

For example, to include untracked content in the diff.

```crystal
diff_options = Grits::DiffOptions.default
diff_options.include_untracked
diff_options.show_untracked_content

data = <<-EOF
This is all new
  lines and should
be present in the new
    Diff
EOF

Grits::Repo.clone(some_url, some_path) do |repo|
  File.write("#{some_path}/saved.txt", data)
  File.write("#{some_path}/new.txt", data)

  repo.index do |index|
    # note that `saved.txt` and `new.txt` have not been added to the stage.
    index.diff_workdir(diff_options) do |diff|
      puts diff.files.size # => 2
    end
  end
end
```