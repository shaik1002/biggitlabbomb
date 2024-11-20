# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::CollaboratorImporter, feature_category: :importers do
  subject(:importer) { described_class.new(collaborator, project, client) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:github_user_id) { rand(1000) }
  let(:collaborator) do
    Gitlab::GithubImport::Representation::Collaborator.from_json_hash(
      'id' => github_user_id,
      'login' => user.username,
      'role_name' => github_role_name
    )
  end

  let(:basic_member_attrs) do
    {
      source: project,
      user_id: user.id,
      member_namespace_id: project.project_namespace_id,
      created_by_id: project.creator_id
    }.stringify_keys
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(github_user_id, user.username).and_return(user.id)
      end
    end

    shared_examples 'role mapping' do |collaborator_role, member_access_level|
      let(:github_role_name) { collaborator_role }

      it 'creates expected member' do
        expect { importer.execute }.to change { project.members.count }
          .from(0).to(1)

        expected_member_attrs = basic_member_attrs.merge(access_level: member_access_level)
        expect(project.members.last).to have_attributes(expected_member_attrs)
      end
    end

    it_behaves_like 'role mapping', 'read', Gitlab::Access::GUEST
    it_behaves_like 'role mapping', 'triage', Gitlab::Access::REPORTER
    it_behaves_like 'role mapping', 'write', Gitlab::Access::DEVELOPER
    it_behaves_like 'role mapping', 'maintain', Gitlab::Access::MAINTAINER
    it_behaves_like 'role mapping', 'admin', Gitlab::Access::OWNER

    context 'when role name is unknown (custom role)' do
      let(:github_role_name) { 'custom_role' }

      it 'raises expected error' do
        expect { importer.execute }.to raise_exception(
          ::Gitlab::GithubImport::ObjectImporter::NotRetriableError
        ).with_message("Unknown GitHub role: #{github_role_name}")
      end
    end

    context 'when user has lower role in a project group' do
      before do
        create(:group_member, group: group, user: user, access_level: Gitlab::Access::DEVELOPER)
      end

      it_behaves_like 'role mapping', 'maintain', Gitlab::Access::MAINTAINER
    end

    context 'when user has higher role in a project group' do
      let(:github_role_name) { 'write' }

      before do
        create(:group_member, group: group, user: user, access_level: Gitlab::Access::MAINTAINER)
      end

      it 'skips creating member for the project' do
        expect { importer.execute }.not_to change { project.members.count }
      end
    end
  end
end
