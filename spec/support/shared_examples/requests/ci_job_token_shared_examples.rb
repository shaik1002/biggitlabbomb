# frozen_string_literal: true

RSpec.shared_examples 'an unauthorized `CI_JOB_TOKEN`' do
  it 'returns a custom error that indicates the required permission to access this endpoint' do
    subject

    expect(response).to have_gitlab_http_status(:unauthorized)
    expect(json_response['message']).to eq(
      "401 Unauthorized - The `#{permission}` permission is required on the target #{resource}"
    )
  end

  context 'when the `include_missing_permission_error` feature flag is disabled' do
    before do
      stub_feature_flags(include_missing_permission_error: false)
    end

    it 'does not include a custom reason' do
      subject

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(json_response['message']).to eq('401 Unauthorized')
    end
  end
end
