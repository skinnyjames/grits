require "./lib/*"
require "./grits/mixins/*"
require "./grits/wrappers/*"
require "./grits/remotable/*"
require "./grits/*"

# A library for interacting with 
# git repositories programmatically.
module Grits
  VERSION = "0.1.0"

  LibGit.init

  # Get a Grits::Oid from a Grits::Tree
  #
  #
  def self.get_tree_id(tree : Grits::Tree) : Oid
    Oid.new(LibGit.tree_id(tree.to_unsafe).value)
  end
end
