# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestConcurrencyLimitWorker'
      end

      include ApplicationWorker

      concurrency_limit -> { 5 }

      def perform(*)
        self.class.work
      end

      def self.work; end
    end
  end

  before do
    stub_const('TestConcurrencyLimitWorker', worker_class)
  end

  around do |example|
    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end
  end

  describe '#call' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(sidekiq_concurrency_limit_middleware: false)
      end

      it 'executes the job' do
        expect(TestConcurrencyLimitWorker).to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

        TestConcurrencyLimitWorker.perform_async('foo')
      end
    end

    context 'when there are jobs in the queue' do
      before do
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:has_jobs_in_queue?)
          .and_return(true)
      end

      it 'defers the job' do
        expect(TestConcurrencyLimitWorker).not_to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:deferred_log).and_call_original
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!)

        TestConcurrencyLimitWorker.perform_async('foo')
      end

      it 'executes the job if resumed' do
        expect(TestConcurrencyLimitWorker).to receive(:work)
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

        related_class = 'Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService'
        Gitlab::ApplicationContext.with_raw_context(related_class: related_class) do
          TestConcurrencyLimitWorker.perform_async('foo')
        end
      end
    end

    context 'when sidekiq_workers are stubbed' do
      before do
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap).to receive(:over_the_limit?)
          .and_return(over_the_limit)
      end

      context 'when under the limit' do
        let(:over_the_limit) { false }

        it 'executes the job' do
          expect(TestConcurrencyLimitWorker).to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:deferred_log)
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:add_to_queue!)

          TestConcurrencyLimitWorker.perform_async('foo')
        end
      end

      context 'when over the limit' do
        let(:over_the_limit) { true }

        it 'defers the job' do
          expect(TestConcurrencyLimitWorker).not_to receive(:work)
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:deferred_log).and_call_original
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:add_to_queue!)

          TestConcurrencyLimitWorker.perform_async('foo')
        end
      end
    end
  end
end
