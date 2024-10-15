# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::CreateRuleService, '#execute', feature_category: :container_registry do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:service) { described_class.new(project, current_user, params) }
  let(:params) { attributes_for(:container_registry_protection_rule, project: project) }

  subject(:service_execute) { service.execute }

  shared_examples 'a successful service response with side effects' do
    it_behaves_like 'returning a success service response' do
      it { is_expected.to have_attributes(errors: be_blank) }

      it do
        is_expected.to have_attributes(
          payload: {
            container_registry_protection_rule:
            be_a(ContainerRegistry::Protection::Rule)
            .and(have_attributes(
              repository_path_pattern: params[:repository_path_pattern],
              minimum_access_level_for_push: params[:minimum_access_level_for_push].to_s,
              minimum_access_level_for_delete: params[:minimum_access_level_for_delete].to_s
            ))
          }
        )
      end
    end

    it 'creates a new container registry protection rule in the database' do
      expect { subject }.to change { ContainerRegistry::Protection::Rule.count }.by(1)

      expect(
        ContainerRegistry::Protection::Rule.where(
          project: project,
          repository_path_pattern: params[:repository_path_pattern],
          minimum_access_level_for_push: params[:minimum_access_level_for_push]
        )
      ).to exist
    end
  end

  shared_examples 'an erroneous service response without side effects' do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it do
        is_expected.to have_attributes(errors: be_present, payload: include(container_registry_protection_rule: nil))
      end
    end

    it 'does not create a new container registry protection rule in the database' do
      expect { subject }.not_to change { ContainerRegistry::Protection::Rule.count }
    end

    it 'does not create a container registry protection rule with the given params' do
      subject

      expect(
        ContainerRegistry::Protection::Rule.where(
          project: project,
          repository_path_pattern: params[:repository_path_pattern],
          minimum_access_level_for_push: params[:minimum_access_level_for_push]
        )
      ).not_to exist
    end
  end

  it_behaves_like 'a successful service response with side effects'

  context 'when fields are invalid' do
    context 'when repository_path_pattern is invalid' do
      let(:params) { super().merge(repository_path_pattern: '') }

      it_behaves_like 'an erroneous service response without side effects',
        message:
          "Repository path pattern can't be blank, " \
          "Repository path pattern should be a valid container repository path with optional wildcard characters., " \
          "and Repository path pattern should start with the project's full path"
    end

    context 'when minimum_access_level_for_delete is invalid' do
      let(:params) { super().merge(minimum_access_level_for_delete: 1000) }

      it_behaves_like 'an erroneous service response without side effects',
        message: "'1000' is not a valid minimum_access_level_for_delete"
    end

    context 'when minimum_access_level_for_push is invalid' do
      let(:params) { super().merge(minimum_access_level_for_push: 1000) }

      it_behaves_like 'an erroneous service response without side effects',
        message: "'1000' is not a valid minimum_access_level_for_push"
    end
  end

  context 'with existing container registry protection rule in the database' do
    let_it_be_with_reload(:existing_container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project)
    end

    context 'when container registry name pattern is slightly different' do
      let(:params) do
        super().merge(
          # The field `repository_path_pattern` is unique; this is why we change the value in a minimum way
          repository_path_pattern: "#{existing_container_registry_protection_rule.repository_path_pattern}-unique",
          minimum_access_level_for_push:
            existing_container_registry_protection_rule.minimum_access_level_for_push
        )
      end

      it_behaves_like 'a successful service response with side effects'
    end

    context 'when field `repository_path_pattern` is taken' do
      let(:params) do
        super().merge(
          repository_path_pattern: existing_container_registry_protection_rule.repository_path_pattern,
          minimum_access_level_for_push: :owner
        )
      end

      it_behaves_like 'an erroneous service response without side effects',
        message: 'Repository path pattern has already been taken'

      it { is_expected.to have_attributes(errors: ['Repository path pattern has already been taken']) }

      it { expect { service_execute }.not_to change { existing_container_registry_protection_rule.updated_at } }
    end
  end

  context 'with disallowed params' do
    let(:params) { super().merge(project_id: 1, unsupported_param: 'unsupported_param_value') }

    it_behaves_like 'a successful service response with side effects'
  end

  context 'with forbidden user access level (project developer role)' do
    # Because of the access level hierarchy, we can assume that
    # other access levels below developer role will also not be able to
    # create container registry protection rules.
    let_it_be(:current_user) { create(:user, developer_of: project) }

    it_behaves_like 'an erroneous service response without side effects',
      message: 'Unauthorized to create a container registry protection rule'
  end
end
