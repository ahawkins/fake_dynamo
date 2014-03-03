require 'bundler/setup'

require 'test_dynamo_db'

require 'rspec'
require 'rack/test'
require 'test_dynamo_db'

ENV['RACK_ENV'] = 'test'

module Utils
  def self.deep_copy(x)
    Marshal.load(Marshal.dump(x))
  end
end

module TestDynamoDB
  class Storage
    def initialize
      delete_db
      init_db
    end
  end
end
