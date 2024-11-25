# frozen_string_literal: true

module Ci
  class RunnerManager < Ci::ApplicationRecord
    include FromUnion
    include RedisCacheable
    include Ci::HasRunnerExecutor
    include Ci::HasRunnerStatus

    # For legacy reasons, the table name is ci_runner_machines in the database
    self.table_name = 'ci_runner_machines'

    AVAILABLE_STATUSES = %w[online offline never_contacted stale].freeze

    # The `UPDATE_CONTACT_COLUMN_EVERY` defines how often the Runner Machine DB entry can be updated
    UPDATE_CONTACT_COLUMN_EVERY = (40.minutes)..(55.minutes)

    belongs_to :runner

    enum creation_state: {
      started: 0,
      finished: 100
    }, _suffix: true

    has_many :runner_manager_builds, inverse_of: :runner_manager, foreign_key: :runner_machine_id,
      class_name: 'Ci::RunnerManagerBuild'
    has_many :builds, through: :runner_manager_builds, class_name: 'Ci::Build'
    belongs_to :runner_version, inverse_of: :runner_managers, primary_key: :version, foreign_key: :version,
      class_name: 'Ci::RunnerVersion'

    validates :runner, presence: true
    validates :system_xid, presence: true, length: { maximum: 64 }
    validates :version, length: { maximum: 2048 }
    validates :revision, length: { maximum: 255 }
    validates :platform, length: { maximum: 255 }
    validates :architecture, length: { maximum: 255 }
    validates :ip_address, length: { maximum: 1024 }
    validates :config, json_schema: { filename: 'ci_runner_config' }

    cached_attr_reader :version, :revision, :platform, :architecture, :ip_address, :contacted_at, :executor_type

    # The `STALE_TIMEOUT` constant defines the how far past the last contact or creation date a runner manager
    # will be considered stale
    STALE_TIMEOUT = 7.days

    scope :stale, -> do
      stale_timestamp = stale_deadline

      created_before_stale_deadline = arel_table[:created_at].lteq(stale_timestamp)
      contacted_before_stale_deadline = arel_table[:contacted_at].lteq(stale_timestamp)

      from_union(
        never_contacted,
        where(contacted_before_stale_deadline),
        remove_duplicates: false
      ).where(created_before_stale_deadline)
    end

    scope :for_runner, ->(runner_id) do
      where(runner_id: runner_id)
    end

    scope :with_system_xid, ->(system_xid) do
      where(system_xid: system_xid)
    end

    scope :with_running_builds, -> do
      where('EXISTS(?)',
        Ci::Build.select(1)
          .joins(:runner_manager_build)
          .running
          .where("#{::Ci::Build.quoted_table_name}.runner_id = #{quoted_table_name}.runner_id")
          .where("#{::Ci::RunnerManagerBuild.quoted_table_name}.runner_machine_id = #{quoted_table_name}.id")
          .limit(1)
      )
    end

    scope :order_id_desc, -> { order(id: :desc) }

    scope :with_version_prefix, ->(value) do
      regex = version_regex_expression_for_version(value)
      value += '.' if regex.end_with?('\.') && !value.end_with?('.')
      substring = Arel::Nodes::NamedFunction.new('substring', [
        Ci::RunnerManager.arel_table[:version],
        Arel.sql("'#{regex}'::text")
      ])
      where(substring.eq(sanitize_sql_like(value)))
    end

    scope :with_upgrade_status, ->(upgrade_status) do
      joins(:runner_version).where(runner_version: { status: upgrade_status })
    end

    def self.online_contact_time_deadline
      Ci::Runner.online_contact_time_deadline
    end

    def self.stale_deadline
      STALE_TIMEOUT.ago
    end

    def self.aggregate_upgrade_status_by_runner_id
      joins(:runner_version)
        .group(:runner_id)
        .maximum(:status)
        .transform_values { |s| Ci::RunnerVersion.statuses.key(s).to_sym }
    end

    def heartbeat(values, update_contacted_at: true)
      ##
      # We can safely ignore writes performed by a runner heartbeat. We do
      # not want to upgrade database connection proxy to use the primary
      # database after heartbeat write happens.
      #
      ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes do
        values = values&.slice(:version, :revision, :platform, :architecture, :ip_address, :config, :executor) || {}

        values.merge!(contacted_at: Time.current, creation_state: :finished) if update_contacted_at

        if values.include?(:executor)
          values[:executor_type] = Ci::Runner::EXECUTOR_NAME_TO_TYPES.fetch(values.delete(:executor), :unknown)
        end

        new_version = values[:version]
        schedule_runner_version_update(new_version) if new_version && new_version != version

        merge_cache_attributes(values)

        # We save data without validation, it will always change due to `contacted_at`
        update_columns(values) if persist_cached_data?
      end
    end

    private

    def persist_cached_data?
      # Use a random threshold to prevent beating DB updates.
      contacted_at_max_age = Random.rand(UPDATE_CONTACT_COLUMN_EVERY)

      real_contacted_at = read_attribute(:contacted_at)
      real_contacted_at.nil? ||
        (Time.current - real_contacted_at) >= contacted_at_max_age
    end

    def schedule_runner_version_update(new_version)
      return unless new_version && Gitlab::Ci::RunnerReleases.instance.enabled?

      Ci::Runners::ProcessRunnerVersionUpdateWorker.perform_async(new_version)
    end

    def self.version_regex_expression_for_version(version)
      case version
      when /\d+\.\d+\.\d+/
        '^\d+\.\d+\.\d+'
      when /\d+\.\d+(\.)?/
        '^\d+\.\d+\.'
      else
        '^\d+\.'
      end
    end
  end
end
