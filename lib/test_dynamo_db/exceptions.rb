module TestDynamoDB
  Error = Class.new StandardError

  class ErrorFactory
    class << self
      def build(description, type = 'com.amazon.dynamodb.v201112045')
        Class.new Error do
          define_method :type do
            type
          end

          define_method :description do
            description
          end

          attr_reader :detail

          def initialize(detail='')
            @detail = detail
            super(detail)
          end

          def response
            {
              '__type' => "#{type}##{class_name}",
              'message' => "#{description}: #{detail}"
            }
          end

          def class_name
            self.class.name.split('::').last
          end

          def status
            400
          end
        end
      end
    end
  end

  UnknownOperationException = ErrorFactory.build '', 'com.amazon.coral.service'
  InvalidParamterValueException = ErrorFactory.build 'invalid parameter'
  ResourceNotFoundException = ErrorFactory.build 'Requested resource not found'
  ResourceInUseException = ErrorFactory.build 'Attempt to change a resource which is still in use'
  ValidationException = ErrorFactory.build 'Validation error detected', 'com.amazon.coral.validate'
  ConditionalCheckFailedException = ErrorFactory.build 'Then conditional request failed'
end
