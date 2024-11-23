# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # TODO Add a top-level documentation comment for the class
    class BackfillApprovalProjectRulesApprovalPolicyRuleId < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillApprovalProjectRulesApprovalPolicyRuleId.prepend_mod
