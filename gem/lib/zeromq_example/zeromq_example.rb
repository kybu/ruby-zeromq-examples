require "zeromq_example/version"
require 'ffi-rzmq'
require 'pp'

module ZeromqEx
  extend self

  def ctx
    if not defined?(@@ctx)
      @@ctx = ZMQ::Context.new
      trap "INT", proc { @@ctx.terminate; exit }
    end
    @@ctx
  end

  def bind_socket(endPoint, socketType)
    sock = ctx.socket socketType
    sock.setsockopt ZMQ::LINGER, 1
    yield sock if block_given?
    sock.bind endPoint

    sock
  end

  def connect_socket(endPoint, socketType)
    sock = ctx.socket socketType
    sock.setsockopt ZMQ::LINGER, 1
    sock.connect endPoint

    sock
  end

  def recv_string_wait(socket, timeout)
    poller = ZMQ::Poller.new
    poller.register_readable socket

    if 0 == poller.poll(timeout)
      poller.delete socket
      nil
    else
      poller.delete socket
      msg = ''
      socket.recv_string msg
      msg
    end
  end
end

require 'zeromq_example/defaults'
require 'zeromq_example/logger'
require 'zeromq_example/db_reader'
require 'zeromq_example/extract'