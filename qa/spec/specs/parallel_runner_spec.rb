# frozen_string_literal: true

require 'etc'

RSpec.describe QA::Specs::ParallelRunner do
  include QA::Support::Helpers::StubEnv

  subject(:runner) { described_class }

  let(:parallel_tests) { instance_double(ParallelTests::CLI, run: nil) }
  let(:parallel_processes) { 2 }

  before do
    allow(ParallelTests::CLI).to receive(:new).and_return(parallel_tests)
    allow(Etc).to receive(:nprocessors).and_return(parallel_processes)
    allow(ENV).to receive(:store)

    allow(QA::Runtime::Browser).to receive(:configure!)
    allow(QA::Runtime::Release).to receive(:perform_before_hooks)

    stub_env("QA_GITLAB_URL", "http://127.0.0.1:3000")
    stub_env("QA_PARALLEL_PROCESSES", parallel_processes.to_s)
  end

  def parallel_cli_args(processes = parallel_processes)
    [
      "--type", "rspec",
      "-n", processes.to_s,
      "--serialize-stdout",
      "--first-is-1",
      "--combine-stderr"
    ]
  end

  shared_examples "parallel cli runner" do |name, processes:, input_args:, received_args:|
    it name do
      runner.run(input_args)

      expect(parallel_tests).to have_received(:run).with([*parallel_cli_args(processes), *received_args])
    end
  end

  it_behaves_like "parallel cli runner", "builds correct arguments without additional rspec args", {
    processes: 2,
    input_args: [],
    received_args: []
  }
  it_behaves_like "parallel cli runner", "builds correct arguments with additional rspec args", {
    processes: 2,
    input_args: ['--force-color'],
    received_args: ['--', '--force-color']
  }
  it_behaves_like "parallel cli runner", "builds correct arguments with specific specs", {
    processes: 1,
    input_args: ["qa/specs/features/api_spec.rb"],
    received_args: ["--", "qa/specs/features/api_spec.rb"]
  }
  it_behaves_like "parallel cli runner", "builds correct arguments with specific specs and rspec options", {
    processes: 2,
    input_args: [
      "--force-color",
      "qa/specs/features/api_spec.rb", "qa/specs/features/api_2_spec.rb", "qa/specs/features/api_2_spec.rb"
    ],
    received_args: [
      "--", "--force-color",
      "--", "qa/specs/features/api_spec.rb", "qa/specs/features/api_2_spec.rb", "qa/specs/features/api_2_spec.rb"
    ]
  }

  context "with QA_GITLAB_URL not set" do
    before do
      stub_env("QA_GITLAB_URL", nil)

      QA::Support::GitlabAddress.instance_variable_set(:@initialized, nil)
    end

    after do
      QA::Support::GitlabAddress.instance_variable_set(:@initialized, nil)
    end

    it "sets QA_GITLAB_URL variable for subprocess" do
      runner.run([])

      expect(ENV).to have_received(:store).with("QA_GITLAB_URL", "http://127.0.0.1:3000")
    end
  end

  context "with QA_PARALLEL_PROCESSES not set" do
    before do
      stub_env("QA_PARALLEL_PROCESSES", nil)
      allow(Etc).to receive(:nprocessors).and_return(8)
    end

    it "sets number of processes to half of available processors" do
      allow(QA::Runtime::Env).to receive(:parallel_processes).and_call_original

      runner.run([])

      expect(QA::Runtime::Env).to have_received(:parallel_processes)
      actual_processes = QA::Runtime::Env.parallel_processes

      expect(parallel_tests).to have_received(:run) do |args|
        expect(args).to eq(parallel_cli_args(actual_processes))
      end
    end
  end
end
