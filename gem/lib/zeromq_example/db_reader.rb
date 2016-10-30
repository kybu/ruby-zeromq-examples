require 'ffi-rzmq'
require 'faker'
require 'zeromq_example/defaults'
require 'zeromq_example/logger'

module ZeromqEx
  class DBReader
    extend LoggerClient
    include LoggerClient

    DBRecord = Struct.new(:id, :name, :birthNumber, :address, :images)

    def self.run(
        endPoint1 = Defaults::DBRECORDS_ENDPOINT,
        endPoint2 = Defaults::DBRECORDS_DONE_ENDPOINT)

      initLogging 'DBReader'
      self.new(endPoint1, endPoint2)
    end

    def initialize(endPoint1, endPoint2)
      @sock = bind_socket endPoint1, ZMQ::PUSH
      @sockRecordsDone = bind_socket endPoint2, ZMQ::PULL

      @rnd = Random.new

      pushDBRecords
    end

    private

    def pushDBRecords
      log "Started"

      dbRecords = 0

      loop do
        record = fetchOneDBRecord
        dbRecords+=1

        log "Fetched #{dbRecords} record(s) from the database"

        @sock.send_string(Marshal.dump record)

        processDoneNotifications

        sleep 1.23
      end
    end

    # This method mocks fetching records from a database
    def fetchOneDBRecord
      e = DBRecord.new

      e.id = @rnd.bytes(10).unpack('H*')

      e.name = Faker::Name.name
      e.birthNumber = Faker::Number.between(129387198, 149085712579712435)
      e.address = [Faker::Address.street_address,
                   Faker::Address.city,
                   Faker::Address.state].join ', '
      e.images = 'binary blob / file paths / ...'

      e
    end

    def processDoneNotifications
      msg = ''
      while @sockRecordsDone.recv_string(msg, ZMQ::DONTWAIT) != -1
        notification = Marshal.load msg
        log "DB record with ID #{notification[:id]} was processed by ProcessDBRecords n.#{notification[:processDBRecords]}"
      end
    end
  end
end
