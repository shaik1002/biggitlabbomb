# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectPipelineResolver < BaseResolver
      include LooksAhead

      calls_gitaly!

      type ::Types::Ci::PipelineType, null: true

      alias_method :project, :object

      argument :id, Types::GlobalIDType[::Ci::Pipeline],
        required: false,
        description: 'Global ID of the Pipeline. For example, "gid://gitlab/Ci::Pipeline/314".',
        prepare: ->(pipeline_id, _ctx) { pipeline_id.model_id }

      argument :iid, GraphQL::Types::ID, # rubocop:disable Graphql/IDType -- Legacy argument using ID type kept for backwards compatibility
        required: false,
        description: 'IID of the Pipeline. For example, "1".'

      argument :sha, GraphQL::Types::String,
        required: false,
        description: 'SHA of the Pipeline. For example, "dyd0f15ay83993f5ab66k927w28673882x99100b".'

      argument :ref, GraphQL::Types::String,
        required: false,
        description: 'REF of the Pipeline.'

      validates required: { one_of: [:id, :iid, :sha, :ref], message: 'Provide one of ID, IID or SHA' }

      def self.resolver_complexity(args, child_complexity:)
        complexity = super
        complexity - 10
      end

      def resolve(id: nil, iid: nil, sha: nil, ref: nil, **args)
        self.lookahead = args.delete(:lookahead)

        if id
          BatchLoader::GraphQL.for(id).batch(key: project) do |ids, loader|
            finder = ::Ci::PipelinesFinder.new(project, current_user, ids: ids)

            apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.id.to_s, pipeline) }
          end
        elsif iid
          BatchLoader::GraphQL.for(iid).batch(key: project) do |iids, loader|
            finder = ::Ci::PipelinesFinder.new(project, current_user, iids: iids)

            apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.iid.to_s, pipeline) }
          end
        elsif ref
          calculated_ref, tag = calculate_ref_and_tag(ref)
          commit_sha = sha || project.commit(calculated_ref)&.sha

          BatchLoader::GraphQL.for(
            { project_id: project.id, ref: calculated_ref, sha: commit_sha, tag: tag }
          ).batch do |where_clauses, loader|
            pipelines = ::Ci::Pipeline.latest_pipeline_union(where_clauses)

            pipelines.each do |pipeline|
              loader.call(
                { project_id: pipeline.project_id, ref: pipeline.ref, sha: pipeline.sha, tag: pipeline.tag },
                pipeline
              )
            end
          end
        else
          BatchLoader::GraphQL.for(sha).batch(key: project) do |shas, loader|
            finder = ::Ci::PipelinesFinder.new(project, current_user, sha: shas)

            apply_lookahead(finder.execute).each { |pipeline| loader.call(pipeline.sha.to_s, pipeline) }
          end
        end
      end

      def unconditional_includes
        [
          { statuses: [:needs] }
        ]
      end

      private

      def calculate_ref_and_tag(ref)
        if ref == 'HEAD'
          [project.default_branch_or_main, false]
        elsif Gitlab::Git.branch_ref(ref)
          [Gitlab::Git.branch_name(ref), false]
        elsif Gitlab::Git.tag_ref(ref)
          [Gitlab::Git.tag_name(ref), true]
        else
          [ref, false]
        end
      end
    end
  end
end
