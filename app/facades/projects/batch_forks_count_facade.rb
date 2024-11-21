# frozen_string_literal: true

module Projects
  class BatchForksCountFacade
    include ActiveModel::API

    attr_accessor :project

    def call
      BatchLoader.for(project).batch do |projects, loader|
        fork_count_per_project = BatchForksCountService.new(projects).refresh_cache_and_retrieve_data

        fork_count_per_project.each do |project, count|
          loader.call(project, count)
        end
      end
    end
  end
end
