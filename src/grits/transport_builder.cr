require "./transport/transport"

module Grits
  alias NetDirection = LibGit::Direction
  alias RemoteCapabilities = LibGit::RemoteCapabilityT

  alias TransportCreateCb = (Transport, Remote -> Bool)
  alias TransportConnectCb = (Transport, String, NetDirection, RemoteConnectOptions -> Bool)
  alias TransportSetConnectOptCb = (Transport, RemoteConnectOptions -> Bool)
  alias TransportCapabilitiesCb = (RemoteCapabilities, Transport -> Bool)
  alias TransportLsCallback = (Array(RemoteHead), Transport -> Bool) #-> int
  alias TransportPushCallback = (Transport, Push -> Bool) # -> int
  alias TransportNegotiateFetchCb = (Transport, Repo, FetchNegotiation -> Bool)
  alias TransportShallowRootsCb = (Array(Oid), Transport -> Nil)
  alias TransportDownloadPackCb = (Transport, Repo, Wrappers::IndexerProgress -> Nil)
  alias TransportConnectedCb = (Transport -> Bool) # -> is connected?
  alias TransportCancelCb = (Transport -> Bool)
  alias TransportFreeCb = (Transport -> Nil)

  alias SubtransportCloseCb = (Subtransport -> Nil)
  alias SubtransportFreeCb = (Subtransport -> Nil)

  alias SmartSubtransportStreamReadCb = (SubtransportStream -> Bool)
  alias SmartSubtransportStreamWriteCb = (SubtransportStream -> Bool)
  alias SmartSubtransportStreamFreeCb = (SubtransportStream -> Nil)
  
  
  class TransportCallbacks < CallbacksState
    # Custom transport callbacks
    define_callback TransportConnectCb, transport_connect
    define_callback TransportSetConnectOptCb, transport_set_connect_options
    define_callback TransportCapabilitiesCb, transport_capabilities
    define_callback TransportLsCallback, transport_ls
    define_callback TransportPushCallback, transport_push
    define_callback TransportOidTypeCb, transport_oid_type
    define_callback TransportNegotiateFetchCb, transport_negotiate_fetch
    define_callback TransportShallowRootsCb, transport_shallow_roots
    define_callback TransportDownloadPackCb, transport_download_pack
    define_callback TransportConnectedCb, transport_is_connected
    define_callback TransportCancelCb, transport_cancel
    define_callback TransportCloseCb, transport_close
    define_callback TransportFreeCb, transport_free

    # Custom sub transport callbacks
    # define_callback SubtransportActionCb, subtransport_action
    define_callback SubtransportCloseCb, subtransport_close
    define_callback SubtransportFreeCb, subtransport_free

    # custom stream callbacks
    define_callback SmartSubtransportStreamReadCb, subtransport_stream_read
    define_callback SmartSubtransportStreamWriteCb, subtransport_stream_write
    define_callback SmartSubtransportStreamFreeCb, subtransport_stream_free
  end

  class TransportBuilder
    include Mixins::Pointable
    include Mixins::Callbacks

    @callbacks = TransportCallbacks.new

    define_callback transport_connect, TransportConnectCb, callbacks
    define_callback transport_set_connect_options, TransportSetConnectOptCb, callbacks 
    define_callback transport_capabilities, TransportCapabilitiesCb, callbacks
    define_callback transport_ls, TransportLsCallback, callbacks
    define_callback transport_push, TransportPushCallback, callbacks
    define_callback transport_oid_type, TransportOidTypeCb, callbacks
    define_callback transport_negotiate_fetch, TransportNegotiateFetchCb, callbacks
    define_callback transport_shallow_roots, TransportShallowRootsCb, callbacks 
    define_callback transport_download_pack, TransportDownloadPackCb, callbacks
    define_callback transport_is_connected, TransportConnectedCb, callbacks
    define_callback transport_cancel, TransportCancelCb, callbacks
    define_callback transport_close, TransportCloseCb, callbacks
    define_callback transport_free, TransportFreeCb, callbacks 

    # Custom sub transport callbacks
    # define_callback subtransport_action, SubtransportActionCb, callbacks # providing this one ourselves.
    define_callback subtransport_close, SubtransportCloseCb, callbacks
    define_callback subtransport_free, SubtransportFreeCb, callbacks

    # custom stream callbacks
    define_callback subtransport_stream_read, SmartSubtransportStreamReadCb, callbacks
    define_callback subtransport_stream_write, SmartSubtransportStreamWriteCb, callbacks
    define_callback subtransport_stream_free, SmartSubtransportStreamFreeCb, callbacks

    def add_callbacks
      @custom_transport_callback = ->(transport_out : LibGit::Transport**, owner : LibGit::Remote*, param : Void*) do
        callbacks = Box(TransportCallbacks).unbox(param)
        custom_transport = LibGit::CustomTransport.new
        custom_transport.owner = owner

        custom_transport.transport.connect = -> (transport : LibGit::Transport*, url : LibC::Char*, direction : LibGit::Direction, opts : LibGit::RemoteConnectOptions*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_connect`" unless state.callbacks.includes?(:transport_connect)

          transportable = Transport.new(transport)
          url_string = String.new(url)
          direction = NetDirection.new(direction)
          options = RemoteConnectOptions.new(opts)

          res = state.callbacks.on_transport_connect.call(transportable, url_string, direction, options)
          res ? 0 : 1
        end

        custom_transport.transport.set_connect_opts = -> (transport : LibGit::Transport*, opts : LibGit::RemoteConnectOptions*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_set_connect_options`" unless state.callbacks.includes?(:transport_set_connect_options)
          
          transportable = Transport.new(transport)
          options = RemoteConnectOptions.new(opts)

          res = state.callbacks.on_transport_set_connect_options.call(transportable, options)
          res ? 0 : 1
        end

        custom_transport.transport.capabilities = ->(abilities : LibGit::RemoteCapabilityT, transport : LibGit::Transport*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_capabilities`" unless state.callbacks.includes?(:transport_capabilities)

          transportable = Transport.new(transport)
          capabilities = RemoteCapabilities.new(abilities)

          res = state.callbacks.on_transport_capabilities.call(capabilities, transportable)
          res ? 0 : 1
        end

        custom_transport.transport.ls = ->(head : LibGit::RemoteHead***, size : LibC::SizeT*, transport : LibGit::Transport*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_ls`" unless state.callbacks.includes?(:transport_ls)

          transportable = Transport.new(transport)
          heads = head.to_slice(size).map { |h| RemoteHead.new(h) }.to_a

          res = state.callbacks.on_transport_ls.call(heads, transportable)
          res ? 0 : 1
        end

        custom_transport.transport.push = ->(transport : LibGit::Transport*, push : LibGit::Push) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_push`" unless state.callbacks.includes?(:transport_push)

          transportable = Transport.new(transport)
          pusher = Push.new(push)

          res = state.callbacks.on_transport_push.call(transportable, pusher)
          res ? 0 : 1
        end

        custom_transport.transport.negotiate_fetch = ->(transport : LibGit::Transport*, repo : LibGit::Repository, fetch_data : LibGit::FetchNegotiation*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_negotiate_fetch`" unless state.callbacks.includes?(:transport_negotiate_fetch)

          transportable = Transport.new(transport)
          repo = Repo.new(repo)
          negotiation = FetchNegotiation.new(fetch_data)

          res = state.callbacks.on_transport_negotiate_fetch.call(transportable, repo, negotiation)
          res ? 0 : 1
        end

        custom_transport.transport.shallow_roots = ->(oids : LibGit::Oidarray*, transport : LibGit::Transport*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_shallow_roots`" unless state.callbacks.includes?(:transport_shallow_roots)

          transportable = Transport.new(transport)
          oid_list = oids.list.to_silce(oids.count).map { |id| Oid.new(id) }.to_a

          res = state.callbacks.on_transport_shallow_roots.call(oid_list, transportable)
          res ? 0 : 1
        end

        custom_transport.transport.download_pack = ->(transport : LibGit::Transport*, repository : LibGit::Repository, stats : LibGit::IndexerProgress*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_download_pack`" unless state.callbacks.includes?(:transport_download_pack)

          transportable = Transport.new(transport)
          repo = Repo.new(repository)
          indexer_progress = IndexerProgress.new(stats)

          res = state.callbacks.on_transport_download_pack.call(transportable, repo, indexer_progress)
          res ? 0 : 1
        end

        custom_transport.transport.is_connected = ->(transport : LibGit::Transport*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_is_connected`" unless state.callbacks.includes?(:transport_is_connected)

          transportable = Transport.new(transport)
          res = state.callbacks.on_transport_is_connected.call(transportable)
          res ? 0 : 1
        end

        custom_transport.transport.cancel = ->(transport : LibGit::Transport*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_cancel`" unless state.callbacks.includes?(:transport_cancel)

          transportable = Transport.new(transport)
          res = state.callbacks.on_transport_cancel.call(transportable)
          res ? 0 : 1
        end

        custom_transport.transport.free = ->(transport : LibGit::Transport*) do
          custom = transport.as(Pointer(LibGit::CustomTransport))
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_free`" unless state.callbacks.includes?(:transport_free)

          transportable = Transport.new(transport)
          res = state.callbacks.on_transport_free.call(transportable)
          res ? 0 : 1
        end
        
        definition =  LibGit::SmartSubtransportDefinition.new
        definition.callback = ->(subtransport : LibGit::SmartSubtransport**, transport : LibGit::Transport*, param : Void*) do
          # this struct is owned by Grits
          custom_subtransport = LibGit::CustomSubtransport.new
          custom_subtransport.owner = transport
          custom_subtransport.subtransport.action = ->(stream : LibGit::SmartSubtransportStream**, transport : LibGit::SmartSubtransport*, url : LibC::Char*, action : LibGit::SmartServiceT) do
            stream.value.subtransport = transport.as(Pointerof(CustomSubtransport))
            
            stream.value.read = ->(stream : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, buffer_size : LibC::SizeT, bytes_read : LibC::SizeT*) do
              custom = stream.value.substransport.as(CustomSubtransport)
              state = Box(TransportCallbacks).unbox(custom.payload)

              raise "Not implmented: `on_subtransport_stream_read`" unless state.callbacks.includes?(:subtransport_stream_read)
              
              streamable = SmartSubtransportStream.new(stream, buffer_size, bytes_read)
            
              res = state.callbacks.on_subtransport_stream_read.call(streamable)
              res ? 0 : 1
            end
            
            stream.value.write = ->(stream : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, len : LibC::SizeT) do
              custom = stream.value.substransport.as(CustomSubtransport)
              state = Box(TransportCallbacks).unbox(custom.payload)

              raise "Not implmented: `on_subtransport_stream_write`" unless state.callbacks.includes?(:subtransport_stream_write)

              streamable = SmartSubtransportStream.new(stream)
              
              res = state.callbacks.on_subtransport_stream_write.call(streamable)
              res ? 0 : 1
            end
            
            # not sure what to do here..
            stream.value.free = ->(stream : LibGit::SmartSubtransportStream*) do
              custom = stream.value.substransport.as(CustomSubtransport)
              state = Box(TransportCallbacks).unbox(custom.payload)

              raise "Not implmented: `on_subtransport_stream_write`" unless state.callbacks.includes?(:subtransport_stream_write)
      
              0
            end
          end

          # huh??
          custom_subtransport.subtransport.close = ->(transport : LibGit::SmartSubtransport*) do
    
            0
          end
      
          # huh??
          custom_subtransport.subtransport.free = ->(transport : LibGit::SmartSubtransport*) do
            
            0
          end

          custom_subtransport.payload = param
          subtransport.value = pointerof(custom_subtransport.subtransport)
          0
        end

        definition.rpc = false
        definition.param = param
        transport_out.value = pointerof(custom_transport)
      
        return LibGit.transport_smart(transport_out, owner, defintion)
      end
    end

    def register(prefix : String)
      add_callbacks
      
      payload = Box(TransportCallbacksState).box(@callbacks)
      Error.giterr(LibGit.transport_register(prefix.to_unsafe, @custom_transport_callback, payload), "Could not register custom transport")
    end
  end
end





# custom_transport_cb = ->(transport_out : LibGit::Transport**, owner : LibGit::Remote*, param : Void*) do
#   custom_transport = LibGit::CustomTransport.new
#   custom_transport.owner = owner
#   custom_transport.transport.connect = -> (transport : LibGit::Transport*, url : LibC::Char*, direction : LibGit::Direction, opts : LibGit::RemoteConnectOptions*) do
#     0
#   end

#   custom_transport.transport.set_connect_opts = -> (transport : LibGit::Transport*, opts : LibGit::RemoteConnectOptions*) do
#     0
#   end

#   custom_transport.transport.capabilities = ->(abilities : LibGit::RemoteCapabilityT, transport : LibGit::Transport*) do
#     0
#   end

#   custom_transport.transport.ls = ->(head : LibGit::RemoteHead***, size : LibC::SizeT*, transport : LibGit::Transport*) do
#     0
#   end

#   custom_transport.transport.negotiate_fetch = ->(transport : LibGit::Transport*, repo : LibGit::Repository, fetch_data : LibGit::FetchNegotiation*) do
#     0
#   end

#   custom_transport.transport.shallow_roots = ->(oids : LibGit::Oidarray*, transport : LibGit::Transport*) do
#     0
#   end

#   custom_transport.transport.download_pack = ->(transport : LibGit::Transport*, repo : LibGit::Repository, stats : LibGit::IndexerProgress*) do
#     0
#   end

#   custom_transport.transport.is_connected = ->(transport : LibGit::Transport*) do
#     0
#   end
  
#   custom_transport.transport.cancel = ->(transport : LibGit::Transport*) do
#     0
#   end

#   custom_transport.transport.close = ->(transport : LibGit::Transport*) do
#     0
#   end

#   custom_transport.transport.free = ->(transport : LibGit::Transport*) do
#     0
#   end


#   definition =  LibGit::SmartSubtransportDefinition.new
#   definition.callback = ->(subtransport : LibGit::SmartSubtransport**, transport : LibGit::Transport*, param : Void*) do
#     # this struct is owned by Grits
#     custom_subtransport = LibGit::CustomSubtransport.new
#     custom_subtransport.owner = transport
#     custom_subtransport.subtransport.action = ->(stream : LibGit::SmartSubtransportStream**, transport : LibGit::SmartSubtransport*, url : LibC::Char*, action : LibGit::SmartServiceT) do
#       stream.value.subtransport = transport.as(Pointerof(CustomSubtransport))
      
#       stream.value.read = ->(stream : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, buffer_size : LibC::SizeT, bytes_read : LibC::SizeT*) do
        
#       end
      
#       stream.value.write = ->(stream : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, len : LibC::SizeT) do
        
#       end
      
#       stream.value.free = ->(stream : LibGit::SmartSubtransportStream*) do
        

#       end

#       0
#     end
    
#     custom_subtransport.subtransport.close = ->(transport : LibGit::SmartSubtransport*) do
    
#       0
#     end

#     custom_subtransport.subtransport.free = ->(transport : LibGit::SmartSubtransport*) do
      
#       0
#     end
    
#     custom_subtransport.payload = param

#     subtransport.value = pointerof(custom_subtransport.subtransport)

#     0
#   end

#   definition.rpc = false
#   definition.param = param
#   transport_out.value = pointerof(custom_transport)

#   return LibGit.transport_smart(transport_out, owner, defintion)
# end

# payload = Box(TransportCallbacksState).box(state)

# LibGit.transport_register("custom", custom_transport_cb, payload)