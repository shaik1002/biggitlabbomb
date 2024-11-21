# frozen_string_literal: true

module WorkItems
  class CountOpenIssuesForProject
    include ActiveModel::API

    attr_accessor :project

    def count(current_user = nil)
      return ::WorkItems::ProjectCountOpenIssuesService.new(project, current_user).count unless current_user.nil?

      BatchLoader.for(project).batch do |projects, loader|
        issues_count_per_project = Projects::BatchOpenIssuesCountService.new(projects).refresh_cache_and_retrieve_data

        issues_count_per_project.each do |project, count|
          loader.call(project, count)
        end
      end
    end

    def refresh_cache
      ::WorkItems::ProjectCountOpenIssuesService
        .new(project)
        .refresh_cache
    end
  end
end
