# frozen_string_literal: true

module ContainerRegistry
  class Registry
    attr_reader :uri, :client, :gitlab_api_client, :path

    def initialize(uri, options = {})
      @uri = uri
      @options = options
      @path = @options[:path] || default_path
      @client = ContainerRegistry::Client.new(@uri, @options)

      import_token = Auth::ContainerRegistryAuthenticationService.import_access_token
      @gitlab_api_client = ContainerRegistry::GitlabApiClient.new(@uri, @options.merge(import_token: import_token))
    end

    private

    def default_path
      @uri.sub(%r{^https?://}, '')
    end
  end
end
