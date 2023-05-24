require "./transport/transport"

module Grits
  alias NetDirection = LibGit::Direction
  alias RemoteCapabilities = LibGit::RemoteCapabilityT

  alias TransportCreateCb = (Transport, Remote -> Bool)
  alias TransportConnectCb = (Transport, String, NetDirection -> Bool)
  alias TransportSetConnectOptCb = (Transport, RemoteConnectOptions -> Bool)
  alias TransportCapabilitiesCb = (RemoteCapabilities, Transport -> Bool)
  alias TransportLsCallback = (Array(RemoteHead), Transport -> Bool) #-> int
  alias TransportPushCallback = (Transport, Push -> Bool) # -> int
  alias TransportNegotiateFetchCb = (Transport, Repo -> Bool)
  alias TransportShallowRootsCb = (Array(Oid), Transport -> Bool)
  alias TransportDownloadPackCb = (Transport, Repo, Wrappers::IndexerProgress -> Bool)
  alias TransportConnectedCb = (Transport -> Bool) # -> is connected?
  alias TransportCancelCb = (Transport -> Bool)
  alias TransportFreeCb = (Transport -> Nil)

  alias SubtransportActionCb = (String, LibGit::SmartServiceT -> Bool)
  alias SubtransportCloseCb = (Subtransport -> Bool)
  alias SubtransportFreeCb = (Subtransport -> Nil)

  alias SmartSubtransportStreamReadCb = (SubtransportStream -> Bool)
  alias SmartSubtransportStreamWriteCb = (SubtransportStream -> Bool)
  alias SmartSubtransportStreamFreeCb = (SubtransportStream -> Nil)
  alias RpcCallback = (-> Bool)
  class TransportCallbacks < CallbacksState
    # configuration
    define_callback RpcCallback, rpc

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
    define_callback SubtransportActionCb, subtransport_action
    define_callback SubtransportCloseCb, subtransport_close
    define_callback SubtransportFreeCb, subtransport_free

    # custom stream callbacks
    define_callback SmartSubtransportStreamReadCb, subtransport_stream_read
    define_callback SmartSubtransportStreamWriteCb, subtransport_stream_write
    define_callback SmartSubtransportStreamFreeCb, subtransport_stream_free
  end

  class TransportBuilder#(T)
    include Mixins::Pointable
    include Mixins::Callbacks

    # @handler : T

    @callbacks = TransportCallbacks.new
    @custom_transport_callback : Proc(Pointer(Pointer(LibGit::Transport)), LibGit::Remote, Pointer(Void), Int32)?

    define_callback rpc, RpcCallback, callbacks
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
    define_callback subtransport_action, SubtransportActionCb, callbacks # providing this one ourselves.
    define_callback subtransport_close, SubtransportCloseCb, callbacks
    define_callback subtransport_free, SubtransportFreeCb, callbacks

    # custom stream callbacks
    define_callback subtransport_stream_read, SmartSubtransportStreamReadCb, callbacks
    define_callback subtransport_stream_write, SmartSubtransportStreamWriteCb, callbacks
    define_callback subtransport_stream_free, SmartSubtransportStreamFreeCb, callbacks

    def initialize(@prefix : String, *, @rpc : Bool = false); end

    def add_callbacks
      @custom_transport_callback = ->(transport_out : LibGit::Transport**, owner : LibGit::Remote, param : Void*) do
        callbacks = Box(TransportCallbacks).unbox(param)
        custom_transport = Pointer(LibGit::Transport).malloc
        custom_transport.value.version = 1

        # Transport changes in latest
        #custom_transport.transport.connect = -> (transport : LibGit::Transport*, url : LibC::Char*, direction : Int32, opts : LibGit::RemoteConnectOptions*) do
         custom_transport.value.connect = -> (transport : LibGit::Transport*, url : LibC::Char*, cb : LibGit::CredentialsAcquireCb, cb_payload : Void*, proxy_opts : LibGit::ProxyOptions*, direction : LibC::Int, flags : LibC::Int) do
          puts "D: CONNECT"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_connect`" unless state.callbacks.includes?(:transport_connect)

          transportable = Transport.new(transport)
          url_string = String.new(url)
          direction = NetDirection.new(direction)

          res = state.on_transport_connect.try(&.call(transportable, url_string, direction))
          res ? 0 : 1
        end
        
        custom_transport.value.set_callbacks = -> (t : LibGit::Transport*, pcb : LibGit::TransportMessageCb, ecb : LibGit::TransportMessageCb, cccb : LibGit::TransportCertificateCheckCb, p : Void*) do
          puts "IN SET CALLBACKS"
          0
        end

        custom_transport.value.set_custom_headers = -> (t : LibGit::Transport*, headers : LibGit::Strarray*) do
          puts "D: SET CUSTOM HEADESR"
          0
        end
        # Not til update
        # custom_transport.transport.set_connect_opts = -> (transport : LibGit::Transport*, opts : LibGit::RemoteConnectOptions*) do
        #   puts "D: SET CONNECT"
        #   custom = transport.as(Pointer(LibGit::CustomTransport)).value
        #   state = Box(TransportCallbacks).unbox(custom.payload)

        #   raise "Not implmented: `on_transport_set_connect_options`" unless state.callbacks.includes?(:transport_set_connect_options)
          
        #   transportable = Transport.new(transport)
        #   options = RemoteConnectOptions.new(opts)

        #   res = state.on_transport_set_connect_options.try(&.call(transportable, options))
        #   res ? 0 : 1
        # end

        # custom_transport.transport.capabilities = ->(abilities : UInt32*, transport : LibGit::Transport*) do
        #   puts "D: CAPS"

        #   custom = transport.as(Pointer(LibGit::CustomTransport)).value
        #   state = Box(TransportCallbacks).unbox(custom.payload)

        #   raise "Not implmented: `on_transport_capabilities`" unless state.callbacks.includes?(:transport_capabilities)

        #   transportable = Transport.new(transport)
        #   capabilities = RemoteCapabilities.new(abilities.value.to_i32)

        #   res = state.on_transport_capabilities.try(&.call(capabilities, transportable))
        #   res ? 0 : 1
        # end

        custom_transport.value.ls = ->(head : LibGit::RemoteHead***, size : LibC::SizeT*, transport : LibGit::Transport*) do
          puts "D: LS"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_ls`" unless state.callbacks.includes?(:transport_ls)

          transportable = Transport.new(transport)
          heads = head.to_slice(size.value).map { |h| RemoteHead.new(h.value) }.to_a

          res = state.on_transport_ls.try(&.call(heads, transportable))
          res ? 0 : 1
        end

        custom_transport.value.push = ->(transport : LibGit::Transport*, push : LibGit::Push, remote_callbacks : LibGit::RemoteCallbacks*) do
          puts "D: PUSH"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_push`" unless state.callbacks.includes?(:transport_push)

          transportable = Transport.new(transport)
          pusher = Push.new(push)

          res = state.on_transport_push.try(&.call(transportable, pusher))
          res ? 0 : 1
        end

        custom_transport.value.negotiate_fetch = ->(transport : LibGit::Transport*, repo : LibGit::Repository, remote_head : LibGit::RemoteHead**, count : LibC::SizeT) do
          puts "D: NEG"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_negotiate_fetch`" unless state.callbacks.includes?(:transport_negotiate_fetch)

          transportable = Transport.new(transport)
          repo = Repo.new(repo)
          #negotiation = FetchNegotiation.new(fetch_data)

          res = state.on_transport_negotiate_fetch.try(&.call(transportable, repo))#, negotiation))
          res ? 0 : 1
        end

        custom_transport.value.read_flags = ->(transport : LibGit::Transport*, flags : LibC::Int*) do
          0
        end

        # custom_transport.transport.shallow_roots = ->(oids : LibGit::Oidarray*, transport : LibGit::Transport*) do
        #   puts "D: SHALLOW"

        #   custom = transport.as(Pointer(LibGit::CustomTransport)).value
        #   state = Box(TransportCallbacks).unbox(custom.payload)

        #   raise "Not implmented: `on_transport_shallow_roots`" unless state.callbacks.includes?(:transport_shallow_roots)

        #   transportable = Transport.new(transport)
        #   oid_list = oids.value.ids.to_slice(oids.value.count).map { |id| Oid.new(id) }.to_a

        #   res = state.on_transport_shallow_roots.try(&.call(oid_list, transportable))
        #   res ? 0 : 1
        # end

        custom_transport.value.download_pack = ->(transport : LibGit::Transport*, repository : LibGit::Repository, stats : LibGit::IndexerProgress*, stats_cb : LibGit::IndexerProgressCb, stats_payload : Void*) do
          puts "D: DP"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_download_pack`" unless state.callbacks.includes?(:transport_download_pack)

          transportable = Transport.new(transport)
          repo = Repo.new(repository)
          indexer_progress = Wrappers::IndexerProgress.new(stats)

          res = state.on_transport_download_pack.try(&.call(transportable, repo, indexer_progress))
          res ? 0 : 1
        end

        custom_transport.value.is_connected = ->(transport : LibGit::Transport*) do
          puts "D: IS_C"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_is_connected`" unless state.callbacks.includes?(:transport_is_connected)

          transportable = Transport.new(transport)
          res = state.on_transport_is_connected.try(&.call(transportable))
          res ? 0 : 1
        end

        custom_transport.value.close = ->(transport : LibGit::Transport*) do
          puts "TRANS: CLOSE"
          0
        end

        custom_transport.value.cancel = ->(transport : LibGit::Transport*) do
          puts "D: CANCEL"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_cancel`" unless state.callbacks.includes?(:transport_cancel)

          transportable = Transport.new(transport)
          res = state.on_transport_cancel.try(&.call(transportable))
          res ? 0 : 1
        end

        custom_transport.value.free = ->(transport : LibGit::Transport*) do
          puts "D: FREE"
          custom = transport.value
          state = Box(TransportCallbacks).unbox(custom.payload)

          raise "Not implmented: `on_transport_free`" unless state.callbacks.includes?(:transport_free)

          transportable = Transport.new(transport)
          state.on_transport_free.try(&.call(transportable))
        end
        
        definition =  LibGit::SmartSubtransportDefinition.new
        definition.callback = ->(subtransport : LibGit::SmartSubtransport**, transport : LibGit::Transport*, param : Void*) do
          puts "D: DEF CB"

          # this struct is owned by Grits
          custom_subtransport = Pointer(LibGit::SmartSubtransport).malloc
          custom_subtransport.value.payload = param


          custom_subtransport.value.action = ->(stream : LibGit::SmartSubtransportStream**, transport : LibGit::SmartSubtransport*, url : LibC::Char*, action : LibGit::SmartServiceT) do
            puts "D: SUBUT ACTION"
            box = Box(TransportCallbacks).unbox(transport.value.payload)

            if cb = box.on_subtransport_action
              u = String.new(url)
              cb.call(u, action)
            end
            # # this is not available in 1.3.2
            # LibGit.remote_connect_options_init(out opts, 1)
            # ret = LibGit.transport_remote_connect_options(pointerof(opts), transport.as(Pointer(LibGit::CustomSubtransport)).value.owner)

            custom_stream = Pointer(LibGit::SmartSubtransportStream).malloc
            custom_stream.value.payload = transport.value.payload
            
            custom_stream.value.read = ->(stream : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, buffer_size : LibC::SizeT, bytes_read : LibC::SizeT*) do
              puts "D: STREAM READ"

              custom = stream.value
              state = Box(TransportCallbacks).unbox(custom.payload)

              raise "Not implmented: `on_subtransport_stream_read`" unless state.callbacks.includes?(:subtransport_stream_read)
              
              streamable = SubtransportStream.new(stream, buffer, buffer_size, bytes_read)
            
              res = state.on_subtransport_stream_read.try(&.call(streamable))
              res ? 0 : 1
            end
            
            custom_stream.value.write = ->(stream : LibGit::SmartSubtransportStream*, buffer : LibC::Char*, len : LibC::SizeT) do
              puts "D: STREAM WRITE"

              custom = stream.value
              state = Box(TransportCallbacks).unbox(custom.payload)

              raise "Not implmented: `on_subtransport_stream_write`" unless state.callbacks.includes?(:subtransport_stream_write)

              streamable = SubtransportStream.new(stream, buffer, len)
              
              res = state.on_subtransport_stream_write.try(&.call(streamable))
              res ? 0 : 1
            end
            
            # not sure what to do here..
            custom_stream.value.free = ->(stream : LibGit::SmartSubtransportStream*) do
              puts "D: STREAM FREE"

              custom = stream.value
              state = Box(TransportCallbacks).unbox(custom.payload)

              raise "Not implmented: `on_subtransport_stream_free`" unless state.callbacks.includes?(:subtransport_stream_free)
      
              # streamable = SubtransportStream.new(stream)
              # state.on_subtransport_stream_free.try(&.call(streamable))

              0
            end

            stream.value = custom_stream
            puts "D: ASSIGNed STREAMT"


            0
          end

          # huh??
          custom_subtransport.value.close = ->(transport : LibGit::SmartSubtransport*) do
            puts "SUB CLOSING"
            cbs = Box(TransportCallbacks).unbox(transport.value.payload)
            puts "D: CLOSING"

            

            puts "D: SUBT CLOSE"
    
            0
          end
      
          # huh??
          custom_subtransport.value.free = ->(transport : LibGit::SmartSubtransport*) do
            puts "D: SUBT FREE"

            nil
          end

          puts "D: ASSIGN CUSTOM SUBT PAYLOAD"
          puts "D: ASSIGN SUBT"

          

          subtransport.value = custom_subtransport

          #return LibGit.smart_subtransport_http(subtransport, transport, param)
          puts "D: ASSIGNED SUBT"
          0
        end

        rpc = 0

        if rpc_call = callbacks.on_rpc
          rpc = rpc_call ? 1 : 0
        end

        definition.rpc = rpc
        definition.param = param # assing the custom transport here.param
        

        puts "D: ASSIGN TRANSPORT VALUE"

        transport_out.value = custom_transport #pointerof(custom_transport).as(Pointer(LibGit::Transport))
      
        puts "D: assign SMART_T"

        return LibGit.transport_smart(transport_out, owner, pointerof(definition))
      end
    end

    def register
      add_callbacks
      
      if custom = @custom_transport_callback
        payload = Box(TransportCallbacks).box(@callbacks)
        Error.giterr(LibGit.transport_register(@prefix.to_unsafe, custom, payload), "Could not register custom transport")
      end
    end

    def unregister
      Error.giterr(LibGit.transport_unregister(@prefix), "Could not unregister custom transport")
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