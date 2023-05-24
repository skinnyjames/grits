require "./spec_helper"
require "http/client"
module ConcurrentHTTP
  enum State
    None
    SendingRequest
    ReceivingResponse
    
    Done
  end

  struct Service
    getter :method, :url, :request_type, :response_type, :chunked
    def initialize(@method : String, @url : String, @request_type : String? = nil, @response_type : String? = nil, @chunked : Bool = false); end
  end

  class Transport
    property :state
    getter :service_types

    @@active_service : Service? = nil

    def initialize
      @state =  State::None
      @service_types = {
        "UploadpackLs" => Service.new("get", "/info/refs?service=git-upload-pack", nil, "application/x-git-upload-pack-advertisement", false),
        "Uploadpack" => Service.new("post", "/git-upload-pack", "application/x-git-upload-pack-request", "application/x-git-upload-pack-result", false),
        "ReceivepackLs" => Service.new("get", "/info/refs?service=git-receive-pack", nil, "application/x-git-receive-pack-advertisement", false),
        "Receivepack" => Service.new("post", "/git-receive-pack", "application/x-git-receive-pack-request", "application/x-git-receive-pack-result", true)
      }
      @queue = [] of Tuple(String, Service)
      @response_queue = [] of HTTP::Client::Response
    end

    def <<(tuple : Tuple(String, Service))
      @queue << tuple
    end

    def response_queue : Array(HTTP::Client::Response)
      @response_queue ||= [] of HTTP::Client::Response
    end

    def make_request(body =nil, &)
      if tuple = @queue.shift?
        url, service = tuple
        self.state = State::SendingRequest

        qualified = "#{url}#{service.url}"

        headers = HTTP::Headers.new

        if rtype = service.request_type
          headers["Content-Type"] = rtype
        end
        headers["Transfer-Encoding"] = "chunked" if service.chunked

        if service.method == "get"

          HTTP::Client.get(qualified, headers: headers) do |io|
            #self.state = State::ReceivingResponse
            yield(io)
          end
        else
          HTTP::Client.post(qualified, body: body, headers: headers) do |io|
            yield(io)
          end
        end
      end
    ensure
    end
  end
end

describe Grits::TransportBuilder, focus: true do
  it "register a custom transport" do
    Grits.register_transport("http") do |b|
      t = ConcurrentHTTP::Transport.new

      b.on_rpc { true }
      b.on_transport_connect do |transport, url, direction|

        false
      end

      b.on_transport_set_connect_options do |transport, options|
        puts options
        true
      end

      b.on_transport_capabilities do |caps, transport|
        false
      end

      b.on_transport_ls do |heads, transport|
        puts "ls"
        true
      end

      b.on_transport_push do |transport, push|
        true
      end

      b.on_transport_negotiate_fetch do |transport, repo|
        puts "negotiate"
        true
      end

      b.on_transport_shallow_roots do |oids, transport|
        true
      end

      b.on_transport_download_pack do |t, repo, progress|
        true
      end

      b.on_transport_is_connected do |t|
        true
      end

      b.on_transport_cancel do |t|
        true
      end

      b.on_transport_free do |t|
      end

      b.on_subtransport_close do |st|
        puts "CLOSING SUB"
        true
      end

      b.on_subtransport_free do |st|
        nil
      end

      b.on_subtransport_action do |url, service|
        puts url, service
        t << { url, t.service_types[service.to_s] }

        true
      end

      b.on_subtransport_stream_read do |stream|
        next true if t.state == ConcurrentHTTP::State::Done

        if t.state == ConcurrentHTTP::State::None
          t.make_request do |res|
            IO.copy(res.body_io, stream)
          end
        else
          a = stream.each_line do |line|
            puts line
            t.make_request(line) do |res|
              IO.copy(res.body_io, stream)
            end
          end
        end

        true
      end

      b.on_subtransport_stream_write do |stream|
        if t.state == ConcurrentHTTP::State::SendingRequest
          stream.each_line do |line|
          puts line
            t.make_request(line) do |res|
              t.state == ConcurrentHTTP::State::ReceivingResponse
              IO.copy(res.body_io, stream)
            end
          end
        else
          t.make_request do |res|
            IO.copy(res.body_io, stream)
          end
        end

        true
      end

      b.on_subtransport_stream_free do |stream|
        nil
      end
    end

    Fixture.clone_repo("http://#{Fixture.host}:3000/skinnyjames/grits_empty_remote.git", "foo") do |repo|
      puts repo.workdir
    end
  end
end
