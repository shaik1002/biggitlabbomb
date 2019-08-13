# frozen_string_literal: true

module HasStatus
  extend ActiveSupport::Concern

  DEFAULT_STATUS = 'created'.freeze
  BLOCKED_STATUS = %w[manual scheduled].freeze
  AVAILABLE_STATUSES = %w[created preparing pending running success failed canceled skipped manual scheduled].freeze
  STARTED_STATUSES = %w[running success failed skipped manual scheduled].freeze
  ACTIVE_STATUSES = %w[preparing pending running].freeze
  COMPLETED_STATUSES = %w[success failed canceled skipped].freeze
  ORDERED_STATUSES = %w[failed preparing pending running manual scheduled canceled success skipped created].freeze
  WARNING_STATUSES = %w[manual failed canceled].to_set.freeze
  STATUSES_ENUM = { created: 0, pending: 1, running: 2, success: 3,
                    failed: 4, canceled: 5, skipped: 6, manual: 7,
                    scheduled: 8, preparing: 9 }.freeze

  UnknownStatusError = Class.new(StandardError)

  class_methods do
    def status
      Gitlab::Ci::Status::GroupedStatuses
        .new(all)
        .one&.dig(:status)
    end

    def started_at
      all.minimum(:started_at)
    end

    def finished_at
      all.maximum(:finished_at)
    end

    def all_state_names
      state_machines.values.flat_map(&:states).flat_map { |s| s.map(&:name) }
    end

    def completed_statuses
      COMPLETED_STATUSES.map(&:to_sym)
    end
  end

  included do
    validates :status, inclusion: { in: AVAILABLE_STATUSES }

    state_machine :status, initial: :created do
      state :created, value: 'created'
      state :preparing, value: 'preparing'
      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
      state :skipped, value: 'skipped'
      state :manual, value: 'manual'
      state :scheduled, value: 'scheduled'
    end

    scope :created, -> { with_status(:created) }
    scope :preparing, -> { with_status(:preparing) }
    scope :relevant, -> { without_status(:created) }
    scope :running, -> { with_status(:running) }
    scope :pending, -> { with_status(:pending) }
    scope :success, -> { with_status(:success) }
    scope :failed, -> { with_status(:failed) }
    scope :canceled, -> { with_status(:canceled) }
    scope :skipped, -> { with_status(:skipped) }
    scope :manual, -> { with_status(:manual) }
    scope :scheduled, -> { with_status(:scheduled) }
    scope :alive, -> { with_status(:created, :preparing, :pending, :running) }
    scope :created_or_pending, -> { with_status(:created, :pending) }
    scope :running_or_pending, -> { with_status(:running, :pending) }
    scope :finished, -> { with_status(:success, :failed, :canceled) }
    scope :failed_or_canceled, -> { with_status(:failed, :canceled) }

    scope :cancelable, -> do
      where(status: [:running, :preparing, :pending, :created, :scheduled])
    end
  end

  def started?
    STARTED_STATUSES.include?(status) && started_at
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def complete?
    COMPLETED_STATUSES.include?(status)
  end

  def blocked?
    BLOCKED_STATUS.include?(status)
  end

  private

  def calculate_duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end
end
