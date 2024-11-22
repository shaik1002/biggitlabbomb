# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Weight, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, weight: 3) }
  let_it_be(:target_work_item) { create(:work_item) }

  let(:params) { {} }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  before do
    # we need to enable the `weight_available?`` method otherwise the weight will always be nil (only on ee)
    allow(work_item).to receive(:weight_available?).and_return(true)
    allow(target_work_item).to receive(:weight_available?).and_return(true)
  end

  describe '#before_create' do
    context 'when target work item does not have weight widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:weight).and_return(false)
      end

      it 'does not copy weight data' do
        expect { callback.before_create }.not_to change { target_work_item.weight }
      end
    end

    context 'when target work item has weight widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:weight).and_return(true)
      end

      it 'copies the weight data' do
        expect { callback.before_create }.to change { target_work_item.weight }.from(nil).to(3)
      end
    end
  end
end
