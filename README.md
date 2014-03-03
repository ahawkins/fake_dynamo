# Test Dynamo DB

A simple resetable DynamoDB implement for tests!

## About this Fork

This is a fork of [Fake Dynamo](ihttps://github.com/ananthakumaran/fake_dynamo).
I do not take credit for the original work. I have changed the code
slightly and modified it's use case. This fork is for writing tests
against DynamoDB. The original fork was cumbersome to setup and reset
between tests. A file was required and it was unclear how to reset it.
This fork addresses those isssues. My fork also has no external
dependencies. Upstream depends on active support and a few other
things. The CLI is also removed. It's not intended for that use
case! **Many thanks to the original author!**

## Caveats

*  `ConsumedCapacityUnits` value will be 1 always.
*  The response size is not constrained by 1mb limit. So operation
   like `BatchGetItem` will return all items irrespective of the
   response size

## Usage

Using this in tests requires some way to redirect HTTP traffic to a
rack app. There are multiple ways to do that. I recommend
[webmock](https://github.com/bblimke/webmock). This gem does not list
it as a dependency because this part is up to you. Once you have the
traffic rerouted, configure your HTTP client to point to a different
URL.

````ruby
require 'minitest/autorun'
require 'webmock/minitest'
require 'test_dynamo_db'

class DyamoDBTest < MiniTest::Unit::TestCase
  def setup
    AWS.config({
      use_ssl: false,
      dynamo_db_endpoint: 'fakedynamo.db',
      dynamo_db_port: 4567,

      # Not required by this gem, but the client may require them
      access_key_id: "xxx",
      secret_access_key:  "xxx"
    })

    stub_request(:any, /fakedynamo/).to_rack(TestDynamoDB::Server)

    # Important! Clear all the state between tests
    TestDynamoDB.reset
  end
end
````
