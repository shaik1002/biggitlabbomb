# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting contributedProjects of the user', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let(:query) { graphql_query_for(:user, user_params, user_fields) }
  let(:user_params) { { username: user.username } }
  let(:user_fields) { 'contributedProjects { nodes { id } }' }

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:private_project) { create(:project, :private) }
  let_it_be(:internal_project) { create(:project, :internal) }

  let(:path) { %i[user contributed_projects nodes] }

  before_all do
    private_project.add_developer(user)
    private_project.add_developer(current_user)

    travel_to(4.hours.from_now) { create(:push_event, project: private_project, author: user) }
    travel_to(3.hours.from_now) { create(:push_event, project: internal_project, author: user) }
    travel_to(2.hours.from_now) { create(:push_event, project: public_project, author: user) }
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  describe 'sorting' do
    let(:user_fields_with_sort) { "contributedProjects(sort: #{sort_parameter}) { nodes { id } }" }
    let(:query_with_sort) { graphql_query_for(:user, user_params, user_fields_with_sort) }

    context 'when sort parameter is not provided' do
      it 'returns contributed projects in default order(LATEST_ACTIVITY_DESC)' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(*path).pluck('id')).to eq([
          private_project.to_global_id.to_s,
          internal_project.to_global_id.to_s,
          public_project.to_global_id.to_s
        ])
      end
    end

    context 'when sort parameter for id is provided' do
      context 'when ID_ASC is provided' do
        let(:sort_parameter) { 'ID_ASC' }

        it 'returns contributed projects in id ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s
          ])
        end
      end

      context 'when ID_DESC is provided' do
        let(:sort_parameter) { 'ID_DESC' }

        it 'returns contributed projects in id descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for name is provided' do
      before_all do
        public_project.update!(name: 'Project A')
        internal_project.update!(name: 'Project B')
        private_project.update!(name: 'Project C')
      end

      context 'when NAME_ASC is provided' do
        let(:sort_parameter) { 'NAME_ASC' }

        it 'returns contributed projects in name ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when NAME_DESC is provided' do
        let(:sort_parameter) { 'NAME_DESC' }

        it 'returns contributed projects in name descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for path is provided' do
      before_all do
        public_project.update!(path: 'Project-1')
        internal_project.update!(path: 'Project-2')
        private_project.update!(path: 'Project-3')
      end

      context 'when PATH_ASC is provided' do
        let(:sort_parameter) { 'PATH_ASC' }

        it 'returns contributed projects in path ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when PATH_DESC is provided' do
        let(:sort_parameter) { 'PATH_DESC' }

        it 'returns contributed projects in path descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for stars is provided' do
      before_all do
        public_project.update!(star_count: 10)
        internal_project.update!(star_count: 20)
        private_project.update!(star_count: 30)
      end

      context 'when STARS_ASC is provided' do
        let(:sort_parameter) { 'STARS_ASC' }

        it 'returns contributed projects in stars ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when STARS_DESC is provided' do
        let(:sort_parameter) { 'STARS_DESC' }

        it 'returns contributed projects in stars descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for latest activity is provided' do
      context 'when LATEST_ACTIVITY_ASC is provided' do
        let(:sort_parameter) { 'LATEST_ACTIVITY_ASC' }

        it 'returns contributed projects in latest activity ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when LATEST_ACTIVITY_DESC is provided' do
        let(:sort_parameter) { 'LATEST_ACTIVITY_DESC' }

        it 'returns contributed projects in latest activity descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for created_at is provided' do
      before_all do
        public_project.update!(created_at: Time.current + 1.hour)
        internal_project.update!(created_at: Time.current + 2.hours)
        private_project.update!(created_at: Time.current + 3.hours)
      end

      context 'when CREATED_ASC is provided' do
        let(:sort_parameter) { 'CREATED_ASC' }

        it 'returns contributed projects in created_at ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when CREATED_DESC is provided' do
        let(:sort_parameter) { 'CREATED_DESC' }

        it 'returns contributed projects in created_at descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end

    context 'when sort parameter for updated_at is provided' do
      before_all do
        public_project.update!(updated_at: Time.current + 1.hour)
        internal_project.update!(updated_at: Time.current + 2.hours)
        private_project.update!(updated_at: Time.current + 3.hours)
      end

      context 'when UPDATED_ASC is provided' do
        let(:sort_parameter) { 'UPDATED_ASC' }

        it 'returns contributed projects in updated_at ascending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ])
        end
      end

      context 'when UPDATED_DESC is provided' do
        let(:sort_parameter) { 'UPDATED_DESC' }

        it 'returns contributed projects in updated_at descending order' do
          post_graphql(query_with_sort, current_user: current_user)

          expect(graphql_data_at(*path).pluck('id')).to eq([
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ])
        end
      end
    end
  end

  describe 'accessible' do
    context 'when user profile is public' do
      context 'when a logged in user with membership in the private project' do
        it 'returns contributed projects with visibility to the logged in user' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_graphql_entity_for(private_project),
            a_graphql_entity_for(internal_project),
            a_graphql_entity_for(public_project)
          )
        end
      end

      context 'when a logged in user with no visibility to the private project' do
        let_it_be(:current_user_2) { create(:user) }

        it 'returns contributed projects with visibility to the logged in user' do
          post_graphql(query, current_user: current_user_2)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_graphql_entity_for(internal_project),
            a_graphql_entity_for(public_project)
          )
        end
      end

      context 'when an anonymous user' do
        it 'returns nothing' do
          post_graphql(query, current_user: nil)

          expect(graphql_data_at(*path)).to be_nil
        end
      end
    end

    context 'when user profile is private' do
      let(:user_params) { { username: private_user.username } }
      let_it_be(:private_user) { create(:user, :private_profile) }

      before_all do
        private_project.add_developer(private_user)
        private_project.add_developer(current_user)

        create(:push_event, project: private_project, author: private_user)
        create(:push_event, project: internal_project, author: private_user)
        create(:push_event, project: public_project, author: private_user)
      end

      context 'when a logged in user' do
        it 'returns no project' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at(*path)).to be_empty
        end
      end

      context 'when an anonymous user' do
        it 'returns nothing' do
          post_graphql(query, current_user: nil)

          expect(graphql_data_at(*path)).to be_nil
        end
      end

      context 'when a logged in user is the user' do
        it 'returns the user\'s all contributed projects' do
          post_graphql(query, current_user: private_user)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_graphql_entity_for(private_project),
            a_graphql_entity_for(internal_project),
            a_graphql_entity_for(public_project)
          )
        end
      end
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:user, :contributed_projects] }

    def pagination_query(params)
      graphql_query_for(:user, user_params, "contributedProjects(#{params}) { #{page_info} nodes { id } }")
    end

    context 'when sorting in latest activity ascending order' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :LATEST_ACTIVITY_ASC }
        let(:first_param) { 1 }
        let(:all_records) do
          [
            public_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            private_project.to_global_id.to_s
          ]
        end
      end
    end

    context 'when sorting in latest activity descending order' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :LATEST_ACTIVITY_DESC }
        let(:first_param) { 1 }
        let(:all_records) do
          [
            private_project.to_global_id.to_s,
            internal_project.to_global_id.to_s,
            public_project.to_global_id.to_s
          ]
        end
      end
    end
  end
end
