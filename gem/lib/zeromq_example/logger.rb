require 'ffi-rzmq'
require 'faker'
require 'zeromq_example/defaults'

module ZeromqEx
  class Logger
    def self.run(
        endPoint1 = Defaults::LOGGER_ENDPOINT,
        endPoint2 = Defaults::LOGGER_HANDSHAKE_ENDPOINT)

      self.new endPoint1, endPoint2
    end

    def initialize(endPoint1, endPoint2)
      @sock = bind_socket endPoint1, ZMQ::SUB do |s|
        # Subscribe to all messages
        s.setsockopt ZMQ::SUBSCRIBE, ''
      end

      @sockHandshake = bind_socket endPoint2, ZMQ::REP

      receiveLogs
    end

    private

    def receiveLogs
      puts 'Ready to receive log messages'

      poller = ZMQ::Poller.new
      poller.register_readable @sock
      poller.register_readable @sockHandshake

      # TODO: expire pending handshakes
      pendingHandshakes = {}

      loop do
        poller.poll
        poller.readables.each do |s|
          # Log message or handshake probe received
          if s == @sock
            logRecord = ''
            @sock.recv_string logRecord

            if logRecord =~ /^HANDSHAKE(.*)/
              pendingHandshakes = {$1 => logRecord}
              next
            end

            logRecord = Marshal.load logRecord

            puts "#{logRecord[:entity]} ## #{logRecord[:msg]}"
            $stdout.flush

          elsif s == @sockHandshake
            msg = ''
            @sockHandshake.recv_string msg

            unless msg =~ /^HANDSHAKE(.*)/
              puts 'Unknown handshake request received!'
              $stdin.flush

              @sockHandshake.send_string 'WHAT?'
              next
            end

            hndShakeID = $1

            if pendingHandshakes.has_key? hndShakeID
              @sockHandshake.send_string 'OK'
              pendingHandshakes.delete hndShakeID
            else
              @sockHandshake.send_string 'NOPE'
            end
          end
        end
      end
    end
  end

  module LoggerClient
    extend self

    def initLogging(entity)
      if not defined?(@@loggerSock)
        @@loggerSock = connect_socket Defaults::LOGGER_ENDPOINT, ZMQ::PUB
        @@loggerHandshake = connect_socket Defaults::LOGGER_HANDSHAKE_ENDPOINT, ZMQ::REQ

        @@entity = entity

        rnd = Random.new
        hndShake = "HANDSHAKE#{Process.pid}#{rnd.bytes(6).unpack('H*')[0]}"
        pubSocketConnected = false

        sleepFor = 0.1
        4.times do
          @@loggerSock.send_string hndShake
          @@loggerHandshake.send_string hndShake

          resp = recv_string_wait @@loggerHandshake, 723
          if resp.nil?
            break

          elsif resp == 'OK'
            pubSocketConnected = true
            break
          end

          sleep sleepFor
          sleepFor*=2
        end

        @@loggerHandshake.close

        if not pubSocketConnected
          puts "Could not connect to a logger. Nevermind."
        end

      else
        raise "called twice!"
      end
    end

    def log(msg)
      logRecord = {entity: @@entity, msg: msg}
      @@loggerSock.send_string Marshal.dump(logRecord)
    end
  end
end