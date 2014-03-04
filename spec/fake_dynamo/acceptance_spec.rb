require 'spec_helper'

module TestDynamoDB
  describe "interating with aws-sdk" do
    before(:each) do
      AWS.config({
        :use_ssl => false,
        :dynamo_db_endpoint => 'fakedynamo.db',
        :dynamo_db_port => 4567,
        :access_key_id => "xxx",
        :secret_access_key => "xxx"
      })

      stub_request(:any, /fakedynamo/).to_rack(TestDynamoDB::Server)
    end

    let(:table_name) { 'test' }
    let(:table) { db.tables[table_name] }
    let(:db) { AWS::DynamoDB.new }
    after { TestDynamoDB.reset }

    before(:each) do
      return if table.exists?

      result = db.tables.create(table_name, 10, 5, {
        hash_key: { name: :string }
      })
      sleep 1 while result.status == :creating
    end

    it "can get/set keys" do
      table.load_schema
      table.items.put name: 'foo'

      table.items.at('foo').exists?.should be_true

      attributes = table.items.at('foo').attributes
      attributes['name'].should eq('foo')

      table.items.at('foo').delete

      table.items.at('foo').exists?.should be_false
    end
  end
end
