# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VirtualRegistries::Packages::Maven, :aggregate_failures, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax
  include WorkhorseHelpers
  include HttpBasicAuthHelpers

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:registry) { create(:virtual_registries_packages_maven_registry, group: group) }
  let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream, registry: registry) }
  let_it_be_with_reload(:cached_response) do
    create(:virtual_registries_packages_maven_cached_response, upstream: upstream)
  end

  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  let_it_be(:deploy_token) do
    create(:deploy_token, :group, groups: [group], read_virtual_registry: true)
  end

  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:headers) { user_basic_auth_header(user, personal_access_token) }

  shared_examples 'disabled feature flag' do
    before do
      stub_feature_flags(virtual_registry_maven: false)
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'disabled dependency proxy' do
    before do
      stub_config(dependency_proxy: { enabled: false })
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'not authenticated user' do
    let(:headers) { {} }

    it_behaves_like 'returning response status', :unauthorized
  end

  shared_examples 'authenticated endpoint' do |success_shared_example_name:|
    %i[personal_access_token deploy_token job_token].each do |token_type|
      context "with a #{token_type}" do
        let_it_be(:user) { deploy_token } if token_type == :deploy_token

        context 'when sent by headers' do
          let(:headers) { super().merge(token_header(token_type)) }

          it_behaves_like success_shared_example_name
        end

        context 'when sent by basic auth' do
          let(:headers) { super().merge(token_basic_auth(token_type)) }

          it_behaves_like success_shared_example_name
        end
      end
    end
  end

  before do
    stub_config(dependency_proxy: { enabled: true }) # not enabled by default
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/registries' do
    let(:group_id) { group.id }
    let(:url) { "/virtual_registries/packages/maven/registries?group_id=#{group_id}" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to contain_exactly(registry.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with valid group_id' do
      it_behaves_like 'successful response'
    end

    context 'with invalid group_id' do
      where(:group_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with missing group_id' do
      let(:url) { '/virtual_registries/packages/maven/registries' }

      it 'returns a bad request with missing group_id' do
        api_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('group_id is missing, group_id is empty')
      end
    end

    context 'with a non member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :not_found
      end

      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :personal_access_token | :basic_auth | :ok
        :deploy_token          | :header     | :ok
        :deploy_token          | :basic_auth | :ok
        :job_token             | :header     | :ok
        :job_token             | :basic_auth | :ok
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'POST /api/v4/virtual_registries/packages/maven/registries' do
    let_it_be(:registry_class) { ::VirtualRegistries::Packages::Maven::Registry }
    let(:url) { '/virtual_registries/packages/maven/registries' }

    subject(:api_request) { post api(url), headers: headers, params: params }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { registry_class.count }.by(1)

        expect(registry_class.last.group_id).to eq(params[:group_id])
      end
    end

    context 'with valid params' do
      let(:params) { { group_id: group.id } }

      it { is_expected.to have_request_urgency(:low) }

      it_behaves_like 'disabled feature flag'
      it_behaves_like 'disabled dependency proxy'
      it_behaves_like 'not authenticated user'

      where(:user_role, :status) do
        :owner      | :created
        :maintainer | :created
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          registry_class.for_group(group).delete_all
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end

      context 'with existing registry' do
        before_all do
          group.add_maintainer(user)
        end

        it 'returns a bad request' do
          api_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to eq({ 'message' => { 'group' => ['has already been taken'] } })
        end
      end

      context 'for authentication' do
        before_all do
          group.add_maintainer(user)
        end

        before do
          registry_class.for_group(group).delete_all
        end

        where(:token, :sent_as, :status) do
          :personal_access_token | :header     | :created
          :personal_access_token | :basic_auth | :created
          :deploy_token          | :header     | :forbidden
          :deploy_token          | :basic_auth | :forbidden
          :job_token             | :header     | :created
          :job_token             | :basic_auth | :created
        end

        with_them do
          let(:headers) do
            case sent_as
            when :header
              token_header(token)
            when :basic_auth
              token_basic_auth(token)
            end
          end

          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with invalid params' do
      before_all do
        group.add_maintainer(user)
      end

      where(:group_id, :status) do
        non_existing_record_id  | :not_found
        'foo'                   | :bad_request
        ''                      | :bad_request
      end

      with_them do
        let(:params) { { group_id: group_id } }

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with subgroup' do
      let(:subgroup) { create(:group, parent: group, visibility_level: group.visibility_level) }

      let(:params) { { group_id: subgroup.id } }

      before_all do
        group.add_maintainer(user)
      end

      it 'returns a bad request beacuse it is not a top level group' do
        api_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => { 'group' => ['must be a top level Group'] } })
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/registries/:id' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq(registry.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with valid registry_id' do
      it_behaves_like 'successful response'
    end

    context 'with invalid registry_id' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with a non member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :forbidden
      end
      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :personal_access_token | :basic_auth | :ok
        :deploy_token          | :header     | :ok
        :deploy_token          | :basic_auth | :ok
        :job_token             | :header     | :ok
        :job_token             | :basic_auth | :ok
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'DELETE /api/v4/virtual_registries/packages/maven/registries/:id' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}" }

    subject(:api_request) { delete api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { ::VirtualRegistries::Packages::Maven::Registry.count }.by(-1)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with valid registry_id' do
      where(:user_role, :status) do
        :owner      | :no_content
        :maintainer | :no_content
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with invalid registry_id' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :not_found
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      before_all do
        group.add_maintainer(user)
      end

      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :no_content
        :personal_access_token | :basic_auth | :no_content
        :deploy_token          | :header     | :forbidden
        :deploy_token          | :basic_auth | :forbidden
        :job_token             | :header     | :no_content
        :job_token             | :basic_auth | :no_content
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/registries/:id/upstreams' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}/upstreams" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to contain_exactly(registry.upstream.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with valid registry' do
      it_behaves_like 'successful response'
    end

    context 'with invalid registry' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with a non member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :forbidden
      end

      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :personal_access_token | :basic_auth | :ok
        :deploy_token          | :header     | :ok
        :deploy_token          | :basic_auth | :ok
        :job_token             | :header     | :ok
        :job_token             | :basic_auth | :ok
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'POST /api/v4/virtual_registries/packages/maven/registries/:id/upstreams' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}/upstreams" }
    let(:params) { { url: 'http://example.com' } }

    subject(:api_request) { post api(url), headers: headers, params: params }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { ::VirtualRegistries::Packages::Maven::Upstream.count }.by(1)
          .and change { ::VirtualRegistries::Packages::Maven::RegistryUpstream.count }.by(1)

        expect(::VirtualRegistries::Packages::Maven::Upstream.last.cache_validity_hours).to eq(
          params[:cache_validity_hours] || ::VirtualRegistries::Packages::Maven::Upstream.new.cache_validity_hours
        )
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with valid params' do
      where(:user_role, :status) do
        :owner      | :created
        :maintainer | :created
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          registry.upstream&.destroy!
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with invalid registry' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :not_found
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for params' do
      where(:params, :status) do
        { url: 'http://example.com', username: 'test', password: 'test', cache_validity_hours: 3 } | :created
        { url: 'http://example.com', username: 'test', password: 'test' }                          | :created
        { url: '', username: 'test', password: 'test' }                                            | :bad_request
        { url: 'http://example.com', username: 'test' }                                            | :bad_request
        {}                                                                                         | :bad_request
      end

      before do
        registry.upstream&.destroy!
      end

      before_all do
        group.add_maintainer(user)
      end

      with_them do
        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with existing upstream' do
      before_all do
        group.add_maintainer(user)
        create(:virtual_registries_packages_maven_upstream, registry: registry)
      end

      it_behaves_like 'returning response status', :conflict
    end

    context 'for authentication' do
      before_all do
        group.add_maintainer(user)
      end

      before do
        registry.upstream&.destroy!
      end

      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :created
        :personal_access_token | :basic_auth | :created
        :deploy_token          | :header     | :forbidden
        :deploy_token          | :basic_auth | :forbidden
        :job_token             | :header     | :created
        :job_token             | :basic_auth | :created
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/registries/:id/upstreams/:upstream_id' do
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry.id}/upstreams/#{upstream.id}" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq(registry.upstream.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with valid params' do
      it_behaves_like 'successful response'
    end

    context 'with a non member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :forbidden
      end

      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :personal_access_token | :basic_auth | :ok
        :deploy_token          | :header     | :ok
        :deploy_token          | :basic_auth | :ok
        :job_token             | :header     | :ok
        :job_token             | :basic_auth | :ok
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'PATCH /api/v4/virtual_registries/packages/maven/registries/:id/upstreams/:upstream_id' do
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry.id}/upstreams/#{upstream.id}" }

    subject(:api_request) { patch api(url), params: params, headers: headers }

    context 'with valid params' do
      let(:params) { { url: 'http://example.com', username: 'test', password: 'test' } }

      it { is_expected.to have_request_urgency(:low) }

      it_behaves_like 'disabled feature flag'
      it_behaves_like 'disabled dependency proxy'
      it_behaves_like 'not authenticated user'

      where(:user_role, :status) do
        :owner      | :ok
        :maintainer | :ok
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          group.send(:"add_#{user_role}", user)
        end

        it_behaves_like 'returning response status', params[:status]
      end

      context 'for authentication' do
        before_all do
          group.add_maintainer(user)
        end

        where(:token, :sent_as, :status) do
          :personal_access_token | :header     | :ok
          :personal_access_token | :basic_auth | :ok
          :deploy_token          | :header     | :forbidden
          :deploy_token          | :basic_auth | :forbidden
          :job_token             | :header     | :ok
          :job_token             | :basic_auth | :ok
        end

        with_them do
          let(:headers) do
            case sent_as
            when :header
              token_header(token)
            when :basic_auth
              token_basic_auth(token)
            end
          end

          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'for params' do
      before_all do
        group.add_maintainer(user)
      end

      let(:params) do
        { url: param_url, username: username, password: password, cache_validity_hours: cache_validity_hours }.compact
      end

      where(:param_url, :username, :password, :cache_validity_hours, :status) do
        nil                  | 'test' | 'test' | 3   | :ok
        'http://example.com' | nil    | 'test' | 3   | :ok
        'http://example.com' | 'test' | nil    | 3   | :ok
        'http://example.com' | 'test' | 'test' | nil | :ok
        nil                  | nil    | nil    | 3   | :ok
        'http://example.com' | 'test' | 'test' | 3   | :ok
        ''                   | 'test' | 'test' | 3   | :bad_request
        'http://example.com' | ''     | 'test' | 3   | :bad_request
        'http://example.com' | 'test' | ''     | 3   | :bad_request
        'http://example.com' | 'test' | 'test' | -1  | :bad_request
        nil                  | nil    | nil    | nil | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'DELETE /api/v4/virtual_registries/packages/maven/registries/:id/upstreams/:upstream_id' do
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry.id}/upstreams/#{upstream.id}" }

    subject(:api_request) { delete api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { ::VirtualRegistries::Packages::Maven::Upstream.count }.by(-1)
          .and change { ::VirtualRegistries::Packages::Maven::RegistryUpstream.count }.by(-1)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'for different user roles' do
      where(:user_role, :status) do
        :owner      | :no_content
        :maintainer | :no_content
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'for authentication' do
      before_all do
        group.add_maintainer(user)
      end

      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :no_content
        :personal_access_token | :basic_auth | :no_content
        :deploy_token          | :header     | :forbidden
        :deploy_token          | :basic_auth | :forbidden
        :job_token             | :header     | :no_content
        :job_token             | :basic_auth | :no_content
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/registries/:id/upstreams/:upstream_id/cached_responses' do
    let(:upstream_id) { upstream.id }
    let(:url) do
      "/virtual_registries/packages/maven/registries/#{registry.id}/upstreams/#{upstream_id}/cached_responses"
    end

    let_it_be(:processing_cached_response) do
      create(
        :virtual_registries_packages_maven_cached_response,
        :processing,
        upstream: upstream,
        group: upstream.group,
        relative_path: cached_response.relative_path
      )
    end

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to contain_exactly(
          cached_response
            .as_json
            .merge('cached_response_id' => Base64.urlsafe_encode64(cached_response.relative_path))
            .except('id', 'object_storage_key', 'file_store', 'status', 'file_final_path')
        )
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'with invalid upstream' do
      where(:upstream_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with a non-member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :forbidden
      end

      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :personal_access_token | :basic_auth | :ok
        :deploy_token          | :header     | :ok
        :deploy_token          | :basic_auth | :ok
        :job_token             | :header     | :ok
        :job_token             | :basic_auth | :ok
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for search param' do
      let(:url) { "#{super()}?search=#{search}" }
      let(:valid_search) { cached_response.relative_path.slice(0, 5) }

      where(:search, :status) do
        ref(:valid_search) | :ok
        'foo'              | :empty
        ''                 | :ok
        nil                | :ok
      end

      with_them do
        if params[:status] == :ok
          it_behaves_like 'successful response'
        else
          it 'returns an empty array' do
            api_request

            expect(json_response).to eq([])
          end
        end
      end
    end
  end

  describe 'DELETE /api/v4/virtual_registries/packages/maven/registries/:id/upstreams/' \
    ':upstream_id/cached_responses/:cached_response_id' do
    let(:cached_response_id) { Base64.urlsafe_encode64(cached_response.relative_path) }
    let(:url) do
      "/virtual_registries/packages/maven/registries/#{registry.id}/upstreams/#{upstream.id}/" \
        "cached_responses/#{cached_response_id}"
    end

    let_it_be(:processing_cached_response) do
      create(
        :virtual_registries_packages_maven_cached_response,
        :processing,
        upstream: upstream,
        group: upstream.group,
        relative_path: cached_response.relative_path
      )
    end

    subject(:api_request) { delete api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { upstream.cached_responses.count }.by(-1)
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled feature flag'
    it_behaves_like 'disabled dependency proxy'
    it_behaves_like 'not authenticated user'

    context 'for different user roles' do
      where(:user_role, :status) do
        :owner      | :no_content
        :maintainer | :no_content
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'for authentication' do
      before_all do
        group.add_maintainer(user)
      end

      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :no_content
        :personal_access_token | :basic_auth | :no_content
        :deploy_token          | :header     | :forbidden
        :deploy_token          | :basic_auth | :forbidden
        :job_token             | :header     | :no_content
        :job_token             | :basic_auth | :no_content
      end

      with_them do
        let(:headers) do
          case sent_as
          when :header
            token_header(token)
          when :basic_auth
            token_basic_auth(token)
          end
        end

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'when error occurs' do
      before_all do
        group.add_maintainer(user)
      end

      before do
        allow_next_found_instance_of(cached_response.class) do |instance|
          allow(instance).to receive(:save).and_return(false)

          errors = ActiveModel::Errors.new(instance).tap { |e| e.add(:cached_response, 'error message') }
          allow(instance).to receive(:errors).and_return(errors)
        end
      end

      it 'returns an error' do
        api_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => { 'cached_response' => ['error message'] } })
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/:id/*path' do
    let_it_be(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }

    let(:url) { "/virtual_registries/packages/maven/#{registry.id}/#{path}" }
    let(:service_response) do
      ServiceResponse.success(
        payload: {
          action: :workhorse_upload_url,
          action_params: { url: upstream.url_for(path), upstream: upstream }
        }
      )
    end

    let(:service_double) do
      instance_double(::VirtualRegistries::Packages::Maven::HandleFileRequestService, execute: service_response)
    end

    before do
      allow(::VirtualRegistries::Packages::Maven::HandleFileRequestService)
        .to receive(:new)
        .with(registry: registry, current_user: user, params: { path: path })
        .and_return(service_double)
    end

    subject(:request) do
      get api(url), headers: headers
    end

    shared_examples 'returning the workhorse send_dependency response' do
      it 'returns a workhorse send_url response' do
        expect(::VirtualRegistries::CachedResponseUploader).to receive(:workhorse_authorize).with(
          a_hash_including(
            use_final_store_path: true,
            final_store_path_root_id: registry.id
          )
        ).and_call_original

        expect(Gitlab::Workhorse).to receive(:send_dependency).with(
          an_instance_of(Hash),
          an_instance_of(String),
          a_hash_including(
            allow_localhost: true,
            ssrf_filter: true,
            allowed_uris: ObjectStoreSettings.enabled_endpoint_uris
          )
        ).and_call_original

        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('send-dependency:')
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['Content-Length'].to_i).to eq(0)
        expect(response.body).to eq('')

        send_data_type, send_data = workhorse_send_data

        expected_headers = upstream.headers.deep_stringify_keys.deep_transform_values do |value|
          [value]
        end

        expected_resp_headers = described_class::NO_BROWSER_EXECUTION_RESPONSE_HEADERS.deep_transform_values do |value|
          [value]
        end

        expected_upload_config = {
          'Headers' => { described_class::UPSTREAM_GID_HEADER => [upstream.to_global_id.to_s] },
          'AuthorizedUploadResponse' => a_kind_of(Hash)
        }

        expect(send_data_type).to eq('send-dependency')
        expect(send_data['Url']).to be_present
        expect(send_data['Headers']).to eq(expected_headers)
        expect(send_data['ResponseHeaders']).to eq(expected_resp_headers)
        expect(send_data['UploadConfig']).to include(expected_upload_config)
      end
    end

    it_behaves_like 'authenticated endpoint',
      success_shared_example_name: 'returning the workhorse send_dependency response' do
        let(:headers) { {} }
      end

    context 'with a valid user' do
      let(:headers) { { 'Private-Token' => personal_access_token.token } }

      context 'with successul handle request service responses' do
        let_it_be(:cached_response) do
          create(
            :virtual_registries_packages_maven_cached_response,
            content_type: 'text/xml',
            upstream: upstream,
            group_id: upstream.group_id,
            relative_path: "/#{path}"
          )
        end

        before do
          # reset the test stub to use the actual service
          allow(::VirtualRegistries::Packages::Maven::HandleFileRequestService).to receive(:new).and_call_original
        end

        context 'when the handle request service returns download_file' do
          it 'returns the workhorse send_url response' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.media_type).to eq(cached_response.content_type)
            # this is a direct download from the file system, workhorse is not involved
            expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to eq(nil)
          end
        end

        context 'when the handle request service returns download_digest' do
          let(:path) { "#{super()}.sha1" }

          it 'returns the requested digest' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.media_type).to eq('text/plain')
            expect(response.body).to eq(cached_response.file_sha1)
          end
        end
      end

      context 'with service response errors' do
        where(:reason, :expected_status) do
          :path_not_present                     | :bad_request
          :unauthorized                         | :unauthorized
          :no_upstreams                         | :bad_request
          :file_not_found_on_upstreams          | :not_found
          :digest_not_found_in_cached_responses | :not_found
          :upstream_not_available               | :bad_request
          :fips_unsupported_md5                 | :bad_request
        end

        with_them do
          let(:service_response) do
            ServiceResponse.error(message: 'error', reason: reason)
          end

          it "returns a #{params[:expected_status]} response" do
            request

            expect(response).to have_gitlab_http_status(expected_status)
            expect(response.body).to include('error') unless expected_status == :unauthorized
          end
        end
      end

      context 'with a web browser' do
        described_class::MAJOR_BROWSERS.each do |browser|
          context "when accessing with a #{browser} browser" do
            before do
              allow_next_instance_of(::Browser) do |b|
                allow(b).to receive("#{browser}?").and_return(true)
              end
            end

            it 'returns a bad request response' do
              request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include(described_class::WEB_BROWSER_ERROR_MESSAGE)
            end
          end
        end
      end

      context 'for a invalid registry id' do
        let(:url) { "/virtual_registries/packages/maven/#{non_existing_record_id}/#{path}" }

        it_behaves_like 'returning response status', :not_found
      end

      it_behaves_like 'disabled feature flag'
      it_behaves_like 'disabled dependency proxy'
    end

    it_behaves_like 'not authenticated user'
  end

  describe 'POST /api/v4/virtual_registries/packages/maven/:id/*path/upload' do
    include_context 'workhorse headers'

    let(:file_upload) { fixture_file_upload('spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.pom') }
    let(:gid_header) { { described_class::UPSTREAM_GID_HEADER => upstream.to_global_id.to_s } }
    let(:additional_headers) do
      gid_header.merge(::Gitlab::Workhorse::SEND_DEPENDENCY_CONTENT_TYPE_HEADER => 'text/xml')
    end

    let(:headers) { workhorse_headers.merge(additional_headers) }

    let_it_be(:path) { 'com/test/package/1.2.3/package-1.2.3.pom' }
    let_it_be(:url) { "/virtual_registries/packages/maven/#{registry.id}/#{path}/upload" }
    let_it_be(:processing_cached_response) do
      create(
        :virtual_registries_packages_maven_cached_response,
        :processing,
        upstream: upstream,
        group: upstream.group,
        relative_path: "/#{path}"
      )
    end

    subject(:request) do
      workhorse_finalize(
        api(url),
        file_key: :file,
        headers: headers,
        params: { file: file_upload, 'file.md5' => 'md5', 'file.sha1' => 'sha1' },
        send_rewritten_field: true
      )
    end

    shared_examples 'returning successful response' do
      it 'accepts the upload', :freeze_time do
        expect { request }.to change { upstream.cached_responses.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(upstream.cached_responses.last).to have_attributes(
          relative_path: "/#{path}",
          upstream_etag: nil,
          upstream_checked_at: Time.zone.now,
          downloaded_at: Time.zone.now,
          file_sha1: kind_of(String),
          file_md5: kind_of(String)
        )
      end
    end

    it_behaves_like 'authenticated endpoint', success_shared_example_name: 'returning successful response'

    context 'with a valid user' do
      let(:headers) { super().merge(token_header(:personal_access_token)) }

      context 'with no workhorse headers' do
        let(:headers) { token_header(:personal_access_token).merge(gid_header) }

        it_behaves_like 'returning response status', :forbidden
      end

      context 'with no permissions on registry' do
        let_it_be(:user) { create(:user) }

        it_behaves_like 'returning response status', :forbidden
      end

      context 'with an invalid upstream gid' do
        let_it_be(:upstream) { build(:virtual_registries_packages_maven_upstream, id: non_existing_record_id) }

        it_behaves_like 'returning response status', :not_found
      end

      context 'with an incoherent upstream gid' do
        let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream) }

        it_behaves_like 'returning response status', :not_found
      end

      it_behaves_like 'disabled feature flag'
      it_behaves_like 'disabled dependency proxy'
    end

    it_behaves_like 'not authenticated user'
  end

  def token_header(token)
    case token
    when :personal_access_token
      { 'PRIVATE-TOKEN' => personal_access_token.token }
    when :deploy_token
      { 'Deploy-Token' => deploy_token.token }
    when :job_token
      { 'Job-Token' => job.token }
    end
  end

  def token_basic_auth(token)
    case token
    when :personal_access_token
      user_basic_auth_header(user, personal_access_token)
    when :deploy_token
      deploy_token_basic_auth_header(deploy_token)
    when :job_token
      job_basic_auth_header(job)
    end
  end
end
