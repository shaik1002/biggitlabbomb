# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProtectDefaultBranchService, feature_category: :source_code_management do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project) }

  describe '#execute' do
    before do
      allow(service)
        .to receive(:protect_default_branch)
    end

    context 'without a default branch' do
      it 'does nothing' do
        allow(service)
          .to receive(:default_branch)
                .and_return(nil)

        service.execute

        expect(service)
          .not_to have_received(:protect_default_branch)
      end
    end

    context 'with a default branch' do
      it 'protects the default branch' do
        allow(service)
          .to receive(:default_branch)
                .and_return('master')

        service.execute

        expect(service)
          .to have_received(:protect_default_branch)
      end
    end
  end

  describe '#protect_default_branch' do
    before do
      allow(service)
        .to receive(:default_branch)
              .and_return('master')

      allow(project)
        .to receive(:change_head)
              .with('master')

      allow(service)
        .to receive(:create_protected_branch)
    end

    context 'when branch protection is needed' do
      before do
        allow(service)
          .to receive(:protect_branch?)
                .and_return(true)

        allow(service)
          .to receive(:create_protected_branch)
      end

      it 'changes the HEAD of the project' do
        service.protect_default_branch

        expect(project)
          .to have_received(:change_head)
      end

      it 'protects the default branch' do
        service.protect_default_branch

        expect(service)
          .to have_received(:create_protected_branch)
      end
    end

    context 'when branch protection is not needed' do
      before do
        allow(service)
          .to receive(:protect_branch?)
                .and_return(false)
      end

      it 'changes the HEAD of the project' do
        service.protect_default_branch

        expect(project)
          .to have_received(:change_head)
      end

      it 'does not protect the default branch' do
        service.protect_default_branch

        expect(service)
          .not_to have_received(:create_protected_branch)
      end
    end

    context 'when protected branch does not exist' do
      before do
        allow(service)
          .to receive(:protected_branch_exists?)
                .and_return(false)
        allow(service)
          .to receive(:protect_branch?)
                .and_return(true)
      end

      it 'changes the HEAD of the project' do
        service.protect_default_branch

        expect(project)
          .to have_received(:change_head)
      end

      it 'protects the default branch' do
        service.protect_default_branch

        expect(service)
          .to have_received(:create_protected_branch)
      end
    end

    context 'when protected branch already exists' do
      before do
        allow(service)
          .to receive(:protected_branch_exists?)
                .and_return(true)
      end

      it 'changes the HEAD of the project' do
        service.protect_default_branch

        expect(project)
          .to have_received(:change_head)
      end

      it 'does not protect the default branch' do
        service.protect_default_branch

        expect(service)
          .not_to have_received(:create_protected_branch)
      end
    end
  end

  describe '#create_protected_branch' do
    it 'creates the protected branch' do
      creator = instance_spy(User)
      create_service = instance_spy(ProtectedBranches::CreateService)
      access_level = Gitlab::Access::DEVELOPER
      params = {
        name: 'master',
        push_access_levels_attributes: [{ access_level: access_level }],
        merge_access_levels_attributes: [{ access_level: access_level }],
        code_owner_approval_required: false,
        allow_force_push: false
      }

      allow(project)
        .to receive(:creator)
              .and_return(creator)

      allow(ProtectedBranches::CreateService)
        .to receive(:new)
              .with(project, creator, params)
              .and_return(create_service)

      allow(service)
        .to receive(:push_access_level)
              .and_return(access_level)

      allow(service)
        .to receive(:merge_access_level)
              .and_return(access_level)

      allow(service)
        .to receive(:default_branch)
              .and_return('master')

      allow(service)
        .to receive(:code_owner_approval_required?)
              .and_return(false)

      allow(service)
        .to receive(:allow_force_push?)
              .and_return(false)

      allow(create_service)
        .to receive(:execute)
              .with(skip_authorization: true)

      service.create_protected_branch

      expect(create_service)
        .to have_received(:execute)
    end
  end

  describe '#protect_branch?' do
    context 'when default branch protection is disabled' do
      it 'returns false' do
        allow(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(Gitlab::Access::BranchProtection.protection_none)

        expect(service.protect_branch?).to eq(false)
      end
    end

    context 'when default branch protection is enabled' do
      before do
        allow(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(Gitlab::Access::BranchProtection.protected_against_developer_pushes)

        allow(service)
          .to receive(:default_branch)
                .and_return('master')
      end

      it 'returns false if the branch is already protected' do
        allow(ProtectedBranch)
          .to receive(:protected?)
                .with(project, 'master')
                .and_return(true)

        expect(service.protect_branch?).to eq(false)
      end

      it 'returns true if the branch is not yet protected' do
        allow(ProtectedBranch)
          .to receive(:protected?)
                .with(project, 'master')
                .and_return(false)

        expect(service.protect_branch?).to eq(true)
      end
    end
  end

  describe '#protected_branch_exists?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:default_branch) { "default-branch" }

    before do
      allow(project).to receive(:default_branch).and_return(default_branch)
      create(:protected_branch, project: nil, group: group, name: default_branch)
    end

    context 'when feature flag `group_protected_branches` disabled' do
      before do
        stub_feature_flags(group_protected_branches: false)
        stub_feature_flags(allow_protected_branches_for_group: false)
      end

      it 'return false' do
        expect(service.protected_branch_exists?).to eq(false)
      end
    end

    context 'when feature flag `group_protected_branches` enabled' do
      before do
        stub_feature_flags(group_protected_branches: true)
        stub_feature_flags(allow_protected_branches_for_group: true)
      end

      it 'return true' do
        expect(service.protected_branch_exists?).to eq(true)
      end
    end
  end

  describe '#default_branch' do
    it 'returns the default branch of the project' do
      allow(project)
        .to receive(:default_branch)
              .and_return('master')

      expect(service.default_branch).to eq('master')
    end
  end

  describe '#push_access_level' do
    context 'when developers can push' do
      it 'returns the DEVELOPER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(Gitlab::Access::BranchProtection.protection_partial)

        expect(service.push_access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when developers can not push' do
      it 'returns the MAINTAINER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(Gitlab::Access::BranchProtection.protected_against_developer_pushes)

        expect(service.push_access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end

  describe '#merge_access_level' do
    context 'when developers can merge' do
      it 'returns the DEVELOPER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(Gitlab::Access::BranchProtection.protected_against_developer_pushes)

        expect(service.merge_access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when developers can not merge' do
      it 'returns the MAINTAINER access level' do
        allow(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(Gitlab::Access::BranchProtection.protection_partial)

        expect(service.merge_access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end

  describe '#allow_force_push?' do
    before do
      allow(project.namespace)
        .to receive(:default_branch_protection_settings)
              .and_return(Gitlab::Access::BranchProtection.protected_against_developer_pushes)
    end

    it 'calls allow_force_push? method of Gitlab::Access::DefaultBranchProtection and returns correct value',
      :aggregate_failures do
      expect_next_instance_of(Gitlab::Access::DefaultBranchProtection) do |instance|
        expect(instance).to receive(:allow_force_push?)
      end

      expect(service.allow_force_push?).to be_falsey
    end
  end

  describe '#code_owner_approval_required?' do
    it 'is falsey' do
      expect(service.code_owner_approval_required?).to be_falsey
    end
  end
end
