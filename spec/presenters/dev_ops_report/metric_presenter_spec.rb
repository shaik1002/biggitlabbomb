# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DevOpsReport::MetricPresenter do
  subject { described_class.new(metric) }

  let(:metric) { build(:dev_ops_report_metric) }

  describe '#idea_to_production_steps' do
    it 'returns percentage score when it depends on a single feature' do
      code_step = subject.idea_to_production_steps.fourth

      expect(code_step.percentage_score).to be_within(0.1).of(50.0)
    end

    it 'returns percentage score when it depends on two features' do
      issue_step = subject.idea_to_production_steps.second

      expect(issue_step.percentage_score).to be_within(0.1).of(53.0)
    end
  end

  describe '#average_percentage_score' do
    it 'calculates an average value across all the features' do
      expect(subject.average_percentage_score).to be_within(0.1).of(55.8)
    end
  end
end
