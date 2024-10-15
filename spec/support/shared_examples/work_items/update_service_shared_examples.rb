# frozen_string_literal: true

RSpec.shared_examples 'update service that triggers GraphQL work_item_updated subscription' do
  let(:update_subject) do
    if defined?(work_item)
      work_item
    elsif defined?(issue)
      issue
    end
  end

  it 'triggers graphql subscription workItemUpdated' do
    expect(GraphqlTriggers).to receive(:work_item_updated).with(update_subject).and_call_original

    execute_service
  end
end
