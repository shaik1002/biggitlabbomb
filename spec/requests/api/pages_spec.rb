# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Pages, feature_category: :pages do
  let_it_be(:project) { create(:project) }
  let_it_be(:admin) { create(:admin) }

  let(:user) { create(:user) }

  before do
    stub_pages_setting(enabled: true)

    create(
      :project_setting,
      project: project,
      pages_unique_domain_enabled: true,
      pages_unique_domain: 'unique-domain')
  end

  context "when get pages setting endpoint" do
    let(:user) { create(:user) }

    it "returns the :ok for project maintainers (and above)" do
      project.add_maintainer(user)

      get api("/projects/#{project.id}/pages", user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "returns the :forbidden for project developers (and below)" do
      project.add_developer(user)

      get api("/projects/#{project.id}/pages", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context "when the pages feature is disabled" do
      it "returns the :not_found when user is not in the project" do
        project.project_feature.update!(pages_access_level: 0)

        get api("/projects/#{project.id}/pages", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when the project has pages deployments", :time_freeze, :aggregate_failures do
      let_it_be(:created_at) { Time.now.utc }

      before_all do
        create(:pages_deployment, path_prefix: '/foo', project: project, created_at: created_at)
        create(:pages_deployment, project: project, created_at: created_at)

        # this one is here to ensure the endpoint don't return "inactive" deployments
        create(
          :pages_deployment,
          path_prefix: '/bar',
          project: project,
          created_at: created_at,
          deleted_at: 5.minutes.from_now)
      end

      it "return the right data" do
        project.add_owner(user)

        get api("/projects/#{project.id}/pages", user)

        expect(json_response["force_https"]).to eq(false)
        expect(json_response["is_unique_domain_enabled"]).to eq(true)
        expect(json_response["url"]).to eq("http://unique-domain.example.com")
        expect(json_response["deployments"]).to match_array([
          {
            "created_at" => created_at.strftime('%Y-%m-%dT%H:%M:%S.%3LZ'),
            "path_prefix" => "/foo",
            "root_directory" => "public",
            "url" => "http://unique-domain.example.com/foo"
          },
          {
            "created_at" => created_at.strftime('%Y-%m-%dT%H:%M:%S.%3LZ'),
            "path_prefix" => nil,
            "root_directory" => "public",
            "url" => "http://unique-domain.example.com/"
          }
        ])
      end
    end
  end

  describe 'PATCH /projects/:id/pages' do
    let(:path) { "/projects/#{project.id}/pages" }
    let(:params) { { pages_unique_domain_enabled: true, pages_https_only: true } }

    before do
      stub_pages_setting(external_https: true)
    end

    context 'when the user is authorized' do
      context 'and the update succeeds' do
        it 'updates the pages settings and returns 200' do
          patch api(path, admin, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['force_https']).to eq(true)
          expect(json_response['is_unique_domain_enabled']).to eq(true)
        end
      end
    end

    context 'when the user is unauthorized' do
      it 'returns a 403 forbidden' do
        patch api(path, user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when pages feature is disabled' do
      before do
        stub_pages_setting(enabled: false)
      end

      it 'returns a 404 not found' do
        patch api(path, admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when there is no project' do
      it 'returns 404 not found' do
        non_existent_project_id = -1
        patch api("/projects/#{non_existent_project_id}/pages", admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the parameters are invalid' do
      let(:invalid_params) { { pages_unique_domain_enabled: nil, pages_https_only: "not_a_boolean" } }

      it 'returns a 400 bad request' do
        patch api(path, admin, admin_mode: true), params: invalid_params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('pages_https_only is invalid')
      end
    end
  end
end
