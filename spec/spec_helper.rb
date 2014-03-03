require 'bundler/setup'

require 'fake_dynamo'

require 'rspec'
require 'rack/test'
require 'fake_dynamo'

ENV['RACK_ENV'] = 'test'

module Utils
  def self.deep_copy(x)
    Marshal.load(Marshal.dump(x))
  end
end

module FakeDynamo
  class Storage
    def initialize
      delete_db
      init_db
    end
  end
end
