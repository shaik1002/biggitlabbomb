# frozen_string_literal: true

unless Rails.env.production?
  require 'rubocop/rake_task'
  require 'yard' # rubocop:disable Rake/Require -- TODO

  RuboCop::RakeTask.new

  namespace :rubocop do
    namespace :check do
      desc 'Run RuboCop check gracefully'
      task :graceful do |_task, args|
        require_relative '../../rubocop/check_graceful_task'

        # Don't reveal TODOs in this run.
        ENV.delete('REVEAL_RUBOCOP_TODO')

        result = RuboCop::CheckGracefulTask.new($stdout).run(args.extras)
        exit result if result.nonzero?
      end
    end

    namespace :todo do
      desc 'Generate RuboCop todos'
      task :generate do |_task, args|
        require 'rubocop'
        require 'active_support/inflector/inflections'
        require_relative '../../rubocop/todo_dir'
        require_relative '../../rubocop/formatter/todo_formatter'

        # Reveal all pending TODOs so RuboCop can pick them up and report
        # during scan.
        ENV['REVEAL_RUBOCOP_TODO'] = '1'

        # Save cop configuration like `RSpec/ContextWording` into
        # `rspec/context_wording.yml` and not into
        # `r_spec/context_wording.yml`.
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'RSpec'
          inflect.acronym 'GraphQL'
        end

        options = %w[
          --parallel
          --format RuboCop::Formatter::TodoFormatter
        ]

        # Convert from Rake::TaskArguments into an Array to make `any?` work as
        # expected.
        cop_names = args.to_a

        todo_dir = RuboCop::TodoDir.new(RuboCop::Formatter::TodoFormatter.base_directory)

        if cop_names.any?
          # We are sorting the cop names to benefit from RuboCop cache which
          # also takes passed parameters into account.
          list = cop_names.sort.join(',')
          options.concat ['--only', list]

          cop_names.each { |cop_name| todo_dir.inspect(cop_name) }
        else
          todo_dir.inspect_all
        end

        puts <<~MSG
          Generating RuboCop TODOs with:
            rubocop #{options.join(' ')}

          This might take a while...
        MSG

        RuboCop::CLI.new.run(options)

        todo_dir.delete_inspected
      end
    end

    YARD::Rake::YardocTask.new(:yard_for_generate_documentation) do |task|
      task.files = ['rubocop/cop/**/*.rb']
      task.options = ['--no-output']
    end

    desc 'Update documentation of all cops'
    task docs: :yard_for_generate_documentation do
      # Pre-load existing cops so we can exclude them
      require 'rubocop'
      require 'rubocop-capybara'
      require 'rubocop-factory_bot'
      require 'rubocop-graphql'
      require 'rubocop-performance'
      require 'rubocop-rails'
      require 'rubocop-rspec'
      require 'rubocop-rspec_rails'

      existing_cops = RuboCop::Cop::Registry.global.to_a

      require_relative '../../lib/gitlab/cops_documentation_generator'

      Dir["rubocop/cop/**/*.rb"].each { |file| require_relative File.join("../..", file) }
      gitlab_cops = RuboCop::Cop::Registry.global.to_a - existing_cops

      deps = %w[
        API BackgroundMigration Capybara CodeReuse Database Gemfile Gemspec Gettext Gitlab Graphql Migration
        Performance QA Rails Rake RSpec Scalability Search SidekiqLoadBalancing Style UsageData
      ]

      Gitlab::CopsDocumentationGenerator.new(departments: deps, cops: gitlab_cops).call

      FileUtils.rm_rf('doc/rubocop/')
      FileUtils.mv('docs/modules/ROOT/pages/', 'doc/rubocop/')
    end
  end
end
