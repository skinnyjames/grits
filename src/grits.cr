require "./lib/*"
require "./grits/mixins/*"
require "./grits/wrappers/*"
require "./grits/remotable/*"
require "./grits/*"

module Grits
  VERSION = "0.1.0"

  LibGit.init

  def self.get_tree_id(tree : Grits::Tree)
    Oid.new(LibGit.tree_id(tree_id))
  end
end
