require 'test_dynamo_db/version'
require 'json'
require 'base64'
require 'test_dynamo_db/exceptions'
require 'test_dynamo_db/validation'
require 'test_dynamo_db/filter'
require 'test_dynamo_db/attribute'
require 'test_dynamo_db/key_schema'
require 'test_dynamo_db/item'
require 'test_dynamo_db/key'
require 'test_dynamo_db/table'
require 'test_dynamo_db/db'
require 'test_dynamo_db/storage'
require 'test_dynamo_db/server'

module TestDynamoDB
  class << self
    def reset
      Storage.instance.reset
      DB.instance.reset
    end
  end
end
