# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module CommitMessage
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/repository/components/delete_blob_modal.vue' do
              element 'commit-message-field'
            end

            base.view 'app/assets/javascripts/repository/components/commit_info.vue' do
              element 'commit-content'
            end

            base.view 'app/views/shared/_commit_message_container.html.haml' do
              element 'commit-message-field'
            end

            base.view 'app/views/projects/commits/_commit.html.haml' do
              element 'commit-content'
            end
          end

          def add_commit_message(message)
            fill_element('commit-message-field', message)
          end

          def has_commit_message?(text)
            has_element?('commit-content', text: text)
          end
        end
      end
    end
  end
end
