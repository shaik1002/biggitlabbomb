module QA
  module Page
    module Profile
      class PersonalAccessTokens < Page::Base
        view 'app/views/shared/_personal_access_tokens_form.html.haml' do
          element :personal_access_token_name_field, 'text_field :name' # rubocop:disable QA/ElementWithPattern
          element :create_token_button, 'submit "Create #{type} token"' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
          element :scopes_api_radios, "label :scopes" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/shared/_personal_access_tokens_created_container.html.haml' do
          element :created_personal_access_token
        end
        view 'app/views/shared/_personal_access_tokens_table.html.haml' do
          element :revoke_button
        end

        def fill_token_name(name)
          fill_in 'personal_access_token_name', with: name
        end

        def check_api
          check 'personal_access_token_scopes_api'
        end

        def create_token
          click_on 'Create personal access token'
        end

        def created_access_token
          find_element(:created_personal_access_token, wait: 30).value
        end

        def has_token_row_for_name?(token_name)
          page.has_css?('tr', text: token_name, wait: 1.0)
        end

        def first_token_row_for_name(token_name)
          page.find('tr', text: token_name, match: :first, wait: 1.0)
        end

        def revoke_first_token_with_name(token_name)
          within first_token_row_for_name(token_name) do
            accept_confirm do
              click_element(:revoke_button)
            end
          end
        end
      end
    end
  end
end
