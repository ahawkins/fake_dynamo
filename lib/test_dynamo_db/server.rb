require 'rack/request'
require 'rack/lock'

module TestDynamoDB
  class Server
    class << self
      def call(env)
        new.call env
      end
    end

    def initialize
      builder= Rack::Builder.new
      builder.use Rack::Lock
      builder.run RequestHandler.new
      @app = builder.to_app
    end

    def call(env)
      @app.call env
    end
  end

  class RequestHandler
    def call(env)
      request = Rack::Request.new env

      if request.post? && request.path_info == '/'
        post_handler request
      elsif request.delete? && request.path_info == '/'
        delete_handler request
      else
        [404, { }, []]
      end
    end

    def post_handler(request)
      status = 200
      headers = { 'Content-Type' => 'application/x-amz-json-1.0' }

      begin
        data = JSON.parse request.body.read
        operation = extract_operation request.env
        response = db.process operation, data
        storage.persist operation, data
        [status, headers, [response.to_json]]
      rescue TestDynamoDB::Error => e
        [e.status, headers, [e.response.to_json]]
      end
    end

    def delete_handler(request)
      db.reset
      storage.reset
      [200, { }, [{success: true}.to_json]]
    end

    def db
      DB.instance
    end

    def storage
      Storage.instance
    end

    def extract_operation(env)
      if env['HTTP_X_AMZ_TARGET'] =~ /DynamoDB_\d+\.([a-zA-z]+)/
        $1
      else
        raise UnknownOperationException
      end
    end
  end
end
