module TestDynamoDB
  class DB

    include Validation

    attr_accessor :tables

    class << self
      def instance
        @db ||= DB.new
      end
    end

    def initialize
      @tables = {}
      @operation_map = {
        'CreateTable' => 'create_table',
        'DescribeTable' => 'describe_table',
        'DeleteTable' => 'delete_table',
        'PutItem' => 'put_item',
        'GetItem' => 'get_item',
        'ListTables' => 'list_tables',
        'BatchWriteItem' => 'batch_write_item',
        'BatchGetItem' => 'batch_get_item',
        'DeleteItem' => 'delete_item',
        'UpdateItem' => 'update_item',
        'Query' => 'query',
        'Scan' => 'scan'
      }
    end

    def reset
      @tables = {}
    end

    def process(operation, data)
      validate_payload(operation, data)
      operation = operation_map.fetch operation do
        fail "Do not know how to handle #{operation}"
      end

      self.send operation, data
    end

    def create_table(data)
      table_name = data['TableName']
      raise ResourceInUseException, "Duplicate table name: #{table_name}" if tables[table_name]

      table = Table.new(data)
      tables[table_name] = table
      response = table.description
      table.activate
      response
    end

    def describe_table(data)
      table = find_table(data['TableName'])
      table.describe_table
    end

    def delete_table(data)
      table_name = data['TableName']
      table = find_table(table_name)
      tables.delete(table_name)
      table.delete
    end

    def list_tables(data)
      start_table = data['ExclusiveStartTableName']
      limit = data['Limit']

      all_tables = tables.keys
      start = 0

      if start_table
        if i = all_tables.index(start_table)
          start = i + 1
        end
      end

      limit ||= all_tables.size
      result_tables = all_tables[start, limit]
      response = { 'TableNames' => result_tables }

      if (start + limit ) < all_tables.size
        last_table = all_tables[start + limit -1]
        response.merge!({ 'LastEvaluatedTableName' => last_table })
      end
      response
    end

    def update_table(data)
      table = find_table(data['TableName'])
      table.update(data['ProvisionedThroughput']['ReadCapacityUnits'], data['ProvisionedThroughput']['WriteCapacityUnits'])
    end

    def self.delegate_to_table(*methods)
      methods.each do |method|
        define_method(method) do |data|
          find_table(data['TableName']).send(method, data)
        end
      end
    end

    delegate_to_table :put_item, :get_item, :delete_item, :update_item, :query, :scan


    def batch_get_item(data)
      response = {}

      data['RequestItems'].each do |table_name, table_data|
        table = find_table(table_name)

        unless response[table_name]
          response[table_name] = { 'ConsumedCapacityUnits' => 1, 'Items' => [] }
        end

        table_data['Keys'].each do |key|
          if item_hash = table.get_raw_item(key, table_data['AttributesToGet'])
            response[table_name]['Items'] << item_hash
          end
        end
      end

      { 'Responses' => response, 'UnprocessedKeys' => {}}
    end

    def batch_write_item(data)
      response = {}
      items = {}
      request_count = 0

      # validation
      data['RequestItems'].each do |table_name, requests|
        table = find_table(table_name)

        items[table.name] ||= {}

        requests.each do |request|
          if request['PutRequest']
            item = table.batch_put_request(request['PutRequest'])
            check_item_conflict(items, table.name, item.key)
            items[table.name][item.key] = item
          else
            key = table.batch_delete_request(request['DeleteRequest'])
            check_item_conflict(items, table.name, key)
            items[table.name][key] = :delete
          end

          request_count += 1
        end
      end

      check_max_request(request_count)

      # real modification
      items.each do |table_name, requests|
        table = find_table(table_name)
        requests.each do |key, value|
          if value == :delete
            table.batch_delete(key)
          else
            table.batch_put(value)
          end
        end
        response[table_name] = { 'ConsumedCapacityUnits' => 1 }
      end

      { 'Responses' => response, 'UnprocessedItems' => {} }
    end

    private

    def check_item_conflict(items, table_name, key)
      if items[table_name][key]
        raise ValidationException, 'Provided list of item keys contains duplicates'
      end
    end


    def find_table(table_name)
      tables[table_name] or raise ResourceNotFoundException, "Table : #{table_name} not found"
    end

    def check_max_request(count)
      if count > 25
        raise ValidationException, 'Too many items requested for the BatchWriteItem call'
      end
    end

    def operation_map
      @operation_map
    end
  end
end
