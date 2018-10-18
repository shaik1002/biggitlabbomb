# frozen_string_literal: true

module QA
  context :manage, :orchestrated, :instance_saml do
    describe 'Instance wide SAML SSO' do
      it 'User logs in to gitlab with SAML SSO' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.act { sign_in_with_saml }

        Vendor::SAMLIdp::Page::Login.act { login_if_required }

        expect(page).to have_content('Welcome to GitLab')
      end
    end
  end
end
