# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectHook, feature_category: :webhooks do
  include_examples 'a hook that gets automatically disabled on failure' do
    let_it_be(:project) { create(:project) }

    let(:hook) { build(:project_hook, project: project) }
    let(:hook_factory) { :project_hook }
    let(:default_factory_arguments) { { project: project } }

    def find_hooks
      project.hooks
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to :project }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:project_hook) }
  end

  describe '.for_projects' do
    it 'finds related project hooks' do
      hook_a = create(:project_hook, project: build(:project))
      hook_b = create(:project_hook, project: build(:project))
      hook_c = create(:project_hook, project: build(:project))

      expect(described_class.for_projects([hook_a.project, hook_b.project]))
        .to contain_exactly(hook_a, hook_b)
      expect(described_class.for_projects(hook_c.project))
        .to contain_exactly(hook_c)
    end
  end

  describe '.push_hooks' do
    it 'returns hooks for push events only' do
      project = build(:project)
      hook = create(:project_hook, project: project, push_events: true)
      create(:project_hook, project: project, push_events: false)
      expect(described_class.push_hooks).to eq([hook])
    end
  end

  describe '.tag_push_hooks' do
    it 'returns hooks for tag push events only' do
      project = build(:project)
      hook = create(:project_hook, project: project, tag_push_events: true)
      create(:project_hook, project: project, tag_push_events: false)
      expect(described_class.tag_push_hooks).to eq([hook])
    end
  end

  describe '.vulnerability_hooks' do
    it 'returns hooks for vulnerability events only' do
      project = build(:project)
      hook = create(:project_hook, project: project, vulnerability_events: true)
      create(:project_hook, project: project, vulnerability_events: false)
      expect(described_class.vulnerability_hooks).to eq([hook])
    end
  end

  describe '#parent' do
    it 'returns the associated project' do
      project = build(:project)
      hook = build(:project_hook, project: project)

      expect(hook.parent).to eq(project)
    end
  end

  describe '#application_context' do
    let_it_be(:hook) { build(:project_hook) }

    it 'includes the type and project' do
      expect(hook.application_context).to include(
        related_class: 'ProjectHook',
        project: hook.project
      )
    end
  end
end
