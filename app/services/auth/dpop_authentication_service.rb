# frozen_string_literal: true

module Auth # rubocop:disable Gitlab/BoundedContexts -- following the same structure as other services
  class DpopAuthenticationService < BaseService
    def initialize(current_user:, personal_access_token_plaintext:, request:)
      @current_user = current_user
      @personal_access_token_plaintext = personal_access_token_plaintext
      @request = request
    end

    def execute!
      # Raise an error unless DpopToken.enabled_for_user?(current_user)
      raise Gitlab::Auth::DpopValidationError, 'DPoP is not enabled for the user' unless current_user.dpop_enabled

      # Extract the raw DPoP token from the request header, and check there's only one header
      dpop_token = Gitlab::Auth::DpopToken.new(data: extract_dpop_from_request!(request))

      Gitlab::Auth::DpopTokenUser.new(token: dpop_token, user: current_user,
        personal_access_token_plaintext: personal_access_token_plaintext).validate!

      { status: :success }
    end

    private

    attr_reader :current_user, :personal_access_token_plaintext, :request

    def extract_dpop_from_request!(request)
      dpop_header_value = request.headers['dpop'].presence
      unless dpop_header_value.is_a?(String) && !dpop_header_value.strip.match?(/[, ]/)
        raise Gitlab::Auth::DpopValidationError, "Multiple DPoP headers must not be present in the request"
      end

      dpop_header_value
    end
  end
end
