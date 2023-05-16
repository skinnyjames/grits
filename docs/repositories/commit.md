# Commiting changes

Commits are done via [Grits::Commit.create][], but it is currently prefered to use an entrypoint.

[Grits::Tree#commit][] will create a commit from a tree object. See [libgit2 docs](https://libgit2.org/libgit2/#HEAD/group/commit/git_commit_create)

A commit takes the folling keyword parameters:

`message`

:   A message for the commit

`author`

:   A [Grits::Commit::SignatureTuple][] detailing the `name`, `email` and `time` that the commit was created.
    Its type is `NamedTuple(name: String, email: String, time: Time)`

`committer`

:   Same form as `author`, but detailing committer information.

`parents`

:   An array of [Grits::Commit][] objects that describe the parents of this commit.

`encoding`

:   The encoding type for the commit message.  Default is `UTF-8`

`update_ref`

:   The reference that will be updated to point to this commit.  Use `HEAD` to update the `HEAD` of the current branch.


## Getting commits / locating parents

`Grits::Repo#commit_at` takes a refspec and yields a `Grits::Commit` at that refspec.  It is provided by [Grits::Mixins::Repository::Commit#commit_at][].


## Example

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
