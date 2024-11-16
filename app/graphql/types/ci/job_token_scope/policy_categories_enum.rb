# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      class PolicyCategoriesEnum < BaseEnum
        graphql_name 'CiJobTokenScopePolicyCategoriesTypes'
        description 'CI_JOB_TOKEN policy category type'

        ::Ci::JobToken::Policies::POLICIES.each do |category|
          value category[:value].to_s.upcase, value: category[:value], description: category[:description]
        end
      end
    end
  end
end
