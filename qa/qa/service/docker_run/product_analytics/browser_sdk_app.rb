# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      module ProductAnalytics
        class BrowserSdkApp < Base
          include Support::API

          attr_reader :port

          def initialize(sdk_host, sdk_app_id)
            # Below is an image of a sample app that uses Product Analytics Browser SDK.
            # The image is created in https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-browser
            # It's buit on every merge to main branch in the repository.
            # Note: set @host_name = 'localhost' here when running locally against GDK.
            @image = 'registry.gitlab.com/gitlab-org/analytics-section/product-analytics/' \
                     'gl-application-sdk-browser/example-app:main'
            @name = 'browser_sdk'
            @sdk_host = URI(sdk_host)
            @sdk_app_id = sdk_app_id
            @port = '8081'

            super()
          end

          def register!
            shell <<~CMD.tr("\n", ' ')
              docker run -d --rm
              --network #{network}
              --hostname #{host_name}
              --name #{@name}
              -p #{@port}:#{@port}
              -e PA_COLLECTOR_URL=#{@sdk_host}
              -e PA_APPLICATION_ID=#{@sdk_app_id}
              #{@image}
              --allowed-hosts #{host_name}
              --port #{@port}
            CMD

            wait_for_app_available
          end

          private

          def wait_for_app_available
            Runtime::Logger.info("Waiting for Browser SDK sample app to become available at http://#{host_name}:#{@port}...")
            Support::Waiter.wait_until(sleep_interval: 1,
              message: "Wait for Browser SDK sample app to become available at http://#{host_name}:#{@port}") { app_available? }
            Runtime::Logger.info('Browser SDK sample app is up!')
          end

          def app_available?
            response = get "http://#{host_name}:#{@port}"
            response.code == 200
          rescue Errno::ECONNRESET, Errno::ECONNREFUSED, RestClient::ServerBrokeConnection => e
            Runtime::Logger.debug("Browser SDK sample app is not yet available: #{e.inspect}")
            false
          end
        end
      end
    end
  end
end
