# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMilestoneReleasesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_milestone_releases_project_id
      feature_category :release_orchestration

      scope_to ->(relation) { relation }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.connection.execute(construct_query(sub_batch: sub_batch.where(backfill_column => nil)))
        end
      end
    end
  end
end
