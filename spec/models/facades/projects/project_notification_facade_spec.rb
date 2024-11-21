# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectNotificationFacade, feature_category: :notifications do
  let(:project) { instance_double(Project) }
  let(:facade) { described_class.new(project: project) }
  let(:old_path_with_namespace) { 'old/path' }
  let(:notification_service) { instance_double(NotificationService) }

  before do
    allow(NotificationService).to receive(:new).and_return(notification_service)
    allow(notification_service).to receive(:project_was_moved)
  end

  describe '#call' do
    it 'sends a project was moved notification' do
      expect(notification_service).to receive(:project_was_moved).with(project, old_path_with_namespace)
      facade.call(old_path_with_namespace)
    end
  end
end
