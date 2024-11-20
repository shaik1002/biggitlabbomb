# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::CommentFormatter, feature_category: :importers do
  let_it_be(:project) { create(:project, import_type: 'gitea') }
  let(:client) { double }
  let(:octocat) { { id: 123456, login: 'octocat', email: 'octocat@example.com' } }
  let(:created_at) { DateTime.strptime('2013-04-10T20:09:31Z') }
  let(:updated_at) { DateTime.strptime('2014-03-03T18:58:10Z') }
  let(:imported_from) { ::Import::SOURCE_GITEA }
  let(:base) do
    {
      body: "I'm having a problem with this.",
      user: octocat,
      commit_id: nil,
      diff_hunk: nil,
      created_at: created_at,
      updated_at: updated_at,
      imported_from: imported_from
    }
  end

  subject(:comment) { described_class.new(project, raw, client) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  describe '#attributes' do
    context 'when do not reference a portion of the diff' do
      let(:raw) { base }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "*Created by: octocat*\n\nI'm having a problem with this.",
          commit_id: nil,
          line_code: nil,
          author_id: project.creator_id,
          type: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when on a portion of the diff' do
      let(:diff) do
        {
          body: 'Great stuff',
          commit_id: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          diff_hunk: "@@ -1,5 +1,9 @@\n class User\n   def name\n-    'John Doe'\n+    'Jane Doe'",
          path: 'file1.txt'
        }
      end

      let(:raw) { base.merge(diff) }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "*Created by: octocat*\n\nGreat stuff",
          commit_id: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          line_code: 'ce1be0ff4065a6e9415095c95f25f47a633cef2b_4_3',
          author_id: project.creator_id,
          type: 'LegacyDiffNote',
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when author is a GitLab user' do
      let(:raw) { base.merge(user: octocat) }

      it 'returns GitLab user id associated with GitHub email as author_id' do
        gl_user = create(:user, email: octocat[:email])

        expect(comment.attributes.fetch(:author_id)).to eq gl_user.id
      end

      it 'returns note without created at tag line' do
        create(:user, email: octocat[:email])

        expect(comment.attributes.fetch(:note)).to eq("I'm having a problem with this.")
      end
    end

    context 'when importing a GitHub project' do
      let(:imported_from) { ::Import::SOURCE_GITHUB }
      let(:raw) { base }

      before do
        project.import_type = 'github'
      end

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "*Created by: octocat*\n\nI'm having a problem with this.",
          commit_id: nil,
          line_code: nil,
          author_id: project.creator_id,
          type: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(comment.attributes).to eq(expected)
      end
    end
  end
end
