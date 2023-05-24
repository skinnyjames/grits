require "./lib/**"
require "./grits/mixins/*"
require "./grits/wrappers/*"
require "./grits/remotable/*"
require "./grits/*"

# A library for interacting with 
# git repositories programmatically.
module Grits
  VERSION = "0.1.0"

  LibGit.init

  @@transports = {} of String => TransportBuilder

  # Get a Grits::Oid from a Grits::Tree
  #
  #
  def self.get_tree_id(tree : Grits::Tree) : Oid
    Oid.new(LibGit.tree_id(tree.to_unsafe).value)
  end

  def self.register_transport(prefix : String, *, rpc : Bool = false)
    builder = TransportBuilder.new(prefix, rpc: rpc)
    yield(builder)
    builder.register
    @@transports[prefix] = builder
  end

  def self.unregister_transport(prefix : String)
    @@transports[prefix].unregister
  end
end
