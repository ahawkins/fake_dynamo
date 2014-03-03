require 'fileutils'
require 'tempfile'
require 'stringio'

module FakeDynamo
  class Storage

    attr_accessor :compacted, :loaded

    class << self
      def instance
        @storage ||= Storage.new
      end
    end

    def initialize
      init_db
    end

    def write_commands
      %w[CreateTable DeleteItem DeleteTable PutItem UpdateItem UpdateTable BatchWriteItem]
    end

    def write_command?(command)
      write_commands.include?(command)
    end

    def init_db
      @db_file = Tempfile.new "fake-dynamo-storage.db"
    end

    def delete_db
      return unless db_file
      db_file.close
      db_file.unlink
    end

    def reset
      @aof.close if @aof
      @aof = nil
      delete_db
    end

    def db
      DB.instance
    end

    def shutdown
      @aof.close if @aof
    end

    def persist(operation, data)
      return unless write_command?(operation)
      db_aof.puts(operation)
      data = data.to_json
      db_aof.puts(data.bytesize + "\n".bytesize)
      db_aof.puts(data)
      db_aof.flush
    end

    def load_aof
      return if @loaded
      file = File.new(db_path, 'r')
      loop do
        operation = file.readline.chomp
        size = Integer(file.readline.chomp)
        data = file.read(size)
        db.process(operation, JSON.parse(data))
      end
    rescue EOFError
      file.close
      compact_if_necessary
      @loaded = true
    end

    def compact_threshold
      100 * 1024 * 1024 # 100mb
    end

    def compact_if_necessary
      return unless File.exists? db_path
      if File.stat(db_path).size > compact_threshold
        compact!
      end
    end

    def compact!
      return if @compacted
      @aof = Tempfile.new('compact')
      db.tables.each do |_, table|
        persist('CreateTable', table.create_table_data)
        table.items.each do |_, item|
          persist('PutItem', table.put_item_data(item))
        end
      end
      @aof.close
      FileUtils.mv(@aof.path, db_path)
      @aof = nil
      @compacted = true
    end

    private
    def db_file
      @db_file
    end

    def db_path
      db_file.path
    end

    def db_aof
      @aof ||= File.new(db_path, 'a')
    end
  end
end
