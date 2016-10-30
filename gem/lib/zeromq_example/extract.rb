require 'ffi-rzmq'
require 'childprocess'
require 'zeromq_example/defaults'
require 'zeromq_example/logger'

module ZeromqEx
  class DoExtractions
    extend  LoggerClient
    include LoggerClient

    def self.spawn(count)
      initLogging 'Extractor main'

      instances = []

      log "Going to spawn #{count} extractor instances."

      count.times do
        id = instances.size+1
        instance = spawnInstance id
        instances << [instance, id]
      end

      loop do
        instances.map! do |x|
          i, id = x
          if i.exited?
            log "Extractor instance n.#{id} exited! Starting a new one."

            [self.spawnInstance(id), id]
          else
            x
          end
        end

        sleep 0.72
      end
    end

    def self.run(
        instanceID = 1,
        endPoint1 = Defaults::DBRECORDS_ENDPOINT,
        endPoint2 = Defaults::DBRECORDS_DONE_ENDPOINT)

      initLogging "Extractor n.#{instanceID}"
      self.new instanceID, endPoint1, endPoint2
    end

    def initialize(instanceID, endPoint1, endPoint2)
      @instanceID = instanceID

      @sock = connect_socket endPoint1, ZMQ::PULL
      @sockRecordsDone = connect_socket endPoint2, ZMQ::PUSH

      doExtractions
    end

    private

    def doExtractions
      log "Started"

      loop do
        rawData = ''
        @sock.recv_string rawData

        record = Marshal.load rawData

        processDBRecord record

        # Send notification about processed DB record
        @sockRecordsDone.send_string Marshal.dump({id: record.id, extractor: @instanceID})
      end
    end

    # This method mocks processing received DB records
    def processDBRecord(record)
      outText = ''
      PP.pp(record, outText)

      log outText
    end

    def self.spawnInstance(id)
      mainScript = File.expand_path $0

      instance = ChildProcess.build(
          '/usr/bin/env', 'ruby',
          mainScript, 'spawned',
          '--id', id.to_s)

      instance.io.inherit!
      instance.start
    end
  end
end