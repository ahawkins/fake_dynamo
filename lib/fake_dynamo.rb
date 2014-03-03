require 'fake_dynamo/version'
require 'json'
require 'base64'
require 'fake_dynamo/exceptions'
require 'fake_dynamo/validation'
require 'fake_dynamo/filter'
require 'fake_dynamo/attribute'
require 'fake_dynamo/key_schema'
require 'fake_dynamo/item'
require 'fake_dynamo/key'
require 'fake_dynamo/table'
require 'fake_dynamo/db'
require 'fake_dynamo/storage'
require 'fake_dynamo/server'

module FakeDynamo
  class << self
    def reset
      Storage.instance.reset
      DB.instance.reset
    end
  end
end
