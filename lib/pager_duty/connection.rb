require 'faraday'
require 'faraday_middleware'
require 'active_support/core_ext'
require 'active_support/time_with_zone'

module PagerDuty

  class Connection
    attr_accessor :connection
    attr_accessor :api_version

    class FileNotFoundError < RuntimeError
    end

    class ApiError < RuntimeError
    end

    class RaiseFileNotFoundOn404 < Faraday::Middleware
      def call(env)
        response = @app.call env
        if response.status == 404
          raise FileNotFoundError, response.env[:url].to_s
        else
          response
        end
      end
    end

    class RaiseApiErrorOnNon200 < Faraday::Middleware
      def call(env)
        response = @app.call env
        unless [200, 201, 204].include?(response.status)
          url = response.env[:url].to_s
          if error = response.body['error']
            # TODO May Need to check error.errors too
            raise ApiError, "Got HTTP #{response['status']} back for #{url}. Error code #{error['code']}: #{error['message']}"
          else
            raise ApiError, "Got HTTP #{response['status']} back for #{url}."
          end
        else
          response
        end
      end
    end

    class ConvertTimesParametersToISO8601  < Faraday::Middleware
      TIME_KEYS = [:since, :until]
      def call(env)

        body = env[:body]
        TIME_KEYS.each do |key|
          if body.has_key?(key) 
            body[key] = body[key].iso8601 if body[key].respond_to?(:iso8601)
          end
        end

        response = @app.call env
      end


    end

    class ParseTimeStrings < Faraday::Middleware
      TIME_KEYS = %w(start end created_on last_status_change_on started_at created_at last_incident_timestamp)

      OBJECT_KEYS = %w(override entry incident alert service)

      def call(env)
        response = @app.call env

        OBJECT_KEYS.each do |key|
          object = env[:body][key]
          parse_object_times(object) if object
          
          collection_key = key.pluralize
          collection = env[:body][collection_key]
          parse_collection_times(collection) if collection
        end

        response
      end

      def parse_collection_times(collection)
        collection.each do |object|
          parse_object_times(object)
        end
      end

      def parse_object_times(object)
        time = Time.zone ? Time.zone : Time

        TIME_KEYS.each do |key|
          object[key] = time.parse(object[key]) if object.has_key?(key)
        end
      end
    end

    def initialize(account, token, api_version = 1)
      @api_version = api_version
      @connection = Faraday.new do |conn|
        conn.url_prefix = "https://#{account}.pagerduty.com/api/v#{api_version}"

        # use token authentication: http://developer.pagerduty.com/documentation/rest/authentication
        conn.token_auth token


        conn.use ParseTimeStrings
        conn.use RaiseApiErrorOnNon200
        # json back, mashify it
        conn.response :mashify
        conn.response :json, :content_type => /\bjson$/
        conn.use RaiseFileNotFoundOn404

        conn.use ConvertTimesParametersToISO8601 
        # use json
        conn.request :json

        conn.adapter  Faraday.default_adapter
      end
    end

    def get(path, options = {})
      # paginate anything being 'get'ed, because the offset/limit isn't intutive
      page = (options.delete(:page) || 1).to_i
      limit = (options.delete(:limit) || 100).to_i
      offset = (page - 1) * limit

      run_request(:get, path, options.merge(:offset => offset, :limit => limit))
    end

    def put(path, options = {})
      run_request(:put, path, options)
    end

    def post(path, options = {})
      run_request(:post, path, options)
    end

    def delete(path, options = {})
      run_request(:delete, path, options)
    end

    def run_request(method, path, options)
      path = path.gsub(/^\//, '') # strip leading slash, to make sure relative things happen on the connection
      headers = nil
      response = connection.run_request(method, path, options, headers)
      response.body
    end

  end
end
