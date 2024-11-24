# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnregisterRunnerService, '#execute', feature_category: :runner do
  let(:caller_info) { { caller: 'spec' } }
  let(:runner) { create(:ci_runner) }

  subject(:execute) { described_class.new(runner, 'some_token', caller_info).execute }

  it 'destroys runner' do
    expect(runner).to receive(:destroy).once.and_call_original

    expect do
      expect(execute).to be_success
    end.to change { Ci::Runner.count }.by(-1)
    expect(runner[:errors]).to be_nil
  end
end
