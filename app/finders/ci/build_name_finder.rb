# frozen_string_literal: true

module Ci
  class BuildNameFinder
    MAX_PER_PAGE = 100

    def initialize(relation:, name:, project:, params: {})
      raise ArgumentError, 'Only Ci::Builds are name searchable' unless relation.klass == Ci::Build
      raise ArgumentError, "Offset Pagination is not supported" if relation.offset_value.present?

      @relation = relation
      @name = name
      @project = project
      @params = params
    end

    def execute
      return relation unless name.to_s.present?

      filter_by_name
    end

    private

    attr_reader :relation, :name, :project, :params

    # rubocop: disable CodeReuse/ActiveRecord -- Need specialized queries for database optimizations
    def filter_by_name
      relation
        .from("(#{build_name_scope.to_sql}) p_ci_build_names, LATERAL (#{ci_builds_query.to_sql}) p_ci_builds")
        .id_before(params[:cursor_id])
        .limit(MAX_PER_PAGE)
    end

    def order
      Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'build_id',
            order_expression: Ci::BuildName.arel_table[:build_id].desc
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'partition_id',
            order_expression: Ci::BuildName.arel_table[:partition_id].desc
          )
        ]
      )
    end

    def scope
      Ci::BuildName.where(project_id: project.id).order(order)
    end

    def array_scope
      Ci::BuildName
        .where(project_id: project.id)
        .loose_index_scan(column: :name)
        .select(:name)
        .where("LOWER(name) LIKE CONCAT('%', ?, '%')", Ci::BuildName.sanitize_sql_like(name.downcase))
    end

    def array_mapping_scope
      ->(name_expression) { Ci::BuildName.where(Ci::BuildName.arel_table[:name].eq(name_expression)) }
    end

    def build_name_scope
      Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
        scope: scope,
        array_scope: array_scope,
        array_mapping_scope: array_mapping_scope
      ).execute
    end

    def ci_builds_query
      relation
        .where("id = p_ci_build_names.build_id and partition_id = p_ci_build_names.partition_id")
        .limit(1)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
