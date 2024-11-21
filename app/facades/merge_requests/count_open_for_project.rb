# frozen_string_literal: true

module MergeRequests
  class CountOpenForProject
    include ActiveModel::API

    attr_accessor :project

    def call
      BatchLoader.for(project).batch do |projects, loader|
        BatchCountOpenService.new(projects)
          .refresh_cache_and_retrieve_data
          .each { |project, count| loader.call(project, count) }
      end
    end
  end
end
