# frozen_string_literal: true

module Ci
  class BuildSourceFinder
    MAX_PER_PAGE = 100

    def initialize(relation:, sources:, project:, params: {})
      raise ArgumentError, 'Only Ci::Builds are source searchable' unless relation.klass == Ci::Build
      raise ArgumentError, "Offset Pagination is not supported" if relation.offset_value.present?

      @relation = relation
      @sources = sources
      @project = project
      @params = params
    end

    def execute
      return relation unless sources.present?

      filter_by_source(relation)
    end

    private

    attr_reader :relation, :sources, :project, :params

    # rubocop: disable CodeReuse/ActiveRecord -- Need specialized queries for database optimizations
    def filter_by_source(build_relation)
      build_source_relation = generate_build_source_relation(apply_pagination_cursor(build_relation))

      main_build_relation =
        Ci::Build.where("(id, partition_id) IN (?)", build_source_relation.select(:build_id, :partition_id))

      # Some callers (graphQL) will invert the ordering based on the relation and the params (asc)
      if params[:invert_ordering]
        main_build_relation.reorder(id: :desc)
      else
        apply_pagination_order(main_build_relation, :id)
      end
    end

    def generate_build_source_relation(build_subrelation)
      build_sources, pipeline_sources = get_source_ids_from_names(sources)
      build_source_relation = Ci::BuildSource
        .where(source: build_sources).or(Ci::BuildSource.where(pipeline_source: pipeline_sources))
        .where(project_id: project.id)

      build_source_relation = apply_pagination_order(build_source_relation, :build_id)
      build_source_relation
        .where("(build_id, partition_id) IN (?)", build_subrelation.select(:id, :partition_id))
        .limit(MAX_PER_PAGE + 1)
    end

    def get_source_ids_from_names(source_names)
      pipeline_sources = []
      build_sources = []
      source_names.each do |source_name|
        if Ci::Pipeline.sources.key?(source_name)
          pipeline_sources << source_name
        elsif Ci::BuildSource.sources.key?(source_name)
          build_sources << source_name
        end
      end

      [build_sources, pipeline_sources]
    end

    # Ci::Builds main ordering is ID DESC which makes ordering reversed
    def apply_pagination_cursor(relation)
      return relation if params[:after].blank? && params[:before].blank?

      if params[:after]
        relation.id_before(Integer(params[:after]))
      else
        relation.id_after(Integer(params[:before]))
      end
    end

    def apply_pagination_order(relation, column)
      if params[:asc].present?
        relation.reorder(column => :asc)
      else
        relation.reorder(column => :desc)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
