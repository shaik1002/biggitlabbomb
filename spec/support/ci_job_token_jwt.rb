# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    # Prevent CI Job Tokens from expiring during long running tests
    stub_const('Ci::JobToken::Jwt::Encode::LEEWAY', 100.minutes)
  end
end
