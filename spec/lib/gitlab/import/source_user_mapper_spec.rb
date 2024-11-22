# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::SourceUserMapper, :request_store, feature_category: :importers do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:import_type) { 'github' }
  let_it_be(:source_hostname) { 'https://github.com' }

  let_it_be(:existing_import_source_user) do
    create(
      :import_source_user,
      namespace: namespace,
      import_type: import_type,
      source_hostname: source_hostname,
      source_user_identifier: '101')
  end

  let_it_be(:import_source_user_from_another_import) { create(:import_source_user) }

  describe '#find_or_create_source_user' do
    let_it_be(:import_user) { create(:namespace_import_user, namespace: namespace).import_user }

    let(:source_name) { 'Pry Contributor' }
    let(:source_username) { 'a_pry_contributor' }
    let(:source_user_identifier) { '123456' }
    let(:cache) { false }

    subject(:find_or_create_source_user) do
      described_class.new(
        namespace: namespace,
        import_type: import_type,
        source_hostname: source_hostname
      ).find_or_create_source_user(
        source_name: source_name,
        source_username: source_username,
        source_user_identifier: source_user_identifier,
        cache: cache
      )
    end

    shared_examples 'creates an import_source_user and a unique placeholder user' do
      it 'creates an import_source_user with an internal placeholder user' do
        expect { find_or_create_source_user }.to change { Import::SourceUser.count }.by(1)

        new_import_source_user = Import::SourceUser.last

        expect(new_import_source_user.placeholder_user).to be_placeholder
        expect(new_import_source_user.attributes).to include({
          'namespace_id' => namespace.id,
          'import_type' => import_type,
          'source_hostname' => source_hostname,
          'source_name' => source_name,
          'source_username' => source_username,
          'source_user_identifier' => source_user_identifier
        })
      end

      it 'creates a new placeholder user with a unique email and username' do
        expect { find_or_create_source_user }.to change { User.where(user_type: :placeholder).count }.by(1)

        new_placeholder_user = User.where(user_type: :placeholder).last

        expect(new_placeholder_user.name).to eq("Placeholder #{source_name}")
        expect(new_placeholder_user.username).to match(/^aprycontributor_placeholder_user_\d+$/)
        expect(new_placeholder_user.email).to match(/^#{import_type}_\h+_\d+@#{Settings.gitlab.host}$/)
      end
    end

    shared_examples 'it does not create an import_source_user or placeholder user' do
      it 'does not create a import_source_user' do
        expect { find_or_create_source_user }.not_to change { Import::SourceUser.count }
      end

      it 'does not create any internal users' do
        expect { find_or_create_source_user }.not_to change { User.count }
      end
    end

    context 'when the placeholder user limit has not been reached' do
      it_behaves_like 'creates an import_source_user and a unique placeholder user'

      it 'caches the created object and does not query the database multiple times' do
        expect(::Import::SourceUser).to receive(:find_source_user).once.and_call_original

        2.times do
          expect(described_class.new(
            namespace: namespace,
            import_type: import_type,
            source_hostname: source_hostname
          ).find_or_create_source_user(
            source_name: source_name,
            source_username: source_username,
            source_user_identifier: source_user_identifier
          ).source_user_identifier).to eq(source_user_identifier)
        end
      end

      context 'when another source user was made while waiting' do
        before do
          allow_next_instance_of(described_class) do |source_user_mapper|
            allow(source_user_mapper).to receive(:create_source_user_mapping)
              .and_raise(described_class::DuplicatedSourceUserError)
          end

          allow(Import::SourceUser).to receive(:find_source_user).and_return(nil, existing_import_source_user)
        end

        it 'returns the existing source user' do
          expect(find_or_create_source_user).to eq(existing_import_source_user)
        end

        it_behaves_like 'it does not create an import_source_user or placeholder user'
      end

      context 'when another source user was made while waiting but we fail to find it' do
        before do
          allow_next_instance_of(described_class) do |source_user_mapper|
            allow(source_user_mapper).to receive(:create_source_user_mapping).and_raise(
              described_class::DuplicatedSourceUserError
            )
          end
        end

        it 'raises an exception' do
          expect { find_or_create_source_user }.to raise_error(described_class::DuplicatedSourceUserError)
        end
      end

      context 'and an import source user exists for current import source' do
        let(:source_user_identifier) { existing_import_source_user.source_user_identifier }

        it 'returns the existing source user' do
          expect(find_or_create_source_user).to eq(existing_import_source_user)
        end

        it_behaves_like 'it does not create an import_source_user or placeholder user'
      end

      context 'when source host name has a path' do
        let(:source_hostname) { 'https://github.com/path' }

        it 'normalizes the source_hostname' do
          expect(find_or_create_source_user.source_hostname).to eq('https://github.com')
        end
      end

      context 'when source host name has a port' do
        let(:source_hostname) { 'https://github.com:8443/path' }

        it 'normalizes the base URI and keeps the port in the source_hostname' do
          expect(find_or_create_source_user.source_hostname).to eq('https://github.com:8443')
        end
      end

      context 'when source host name has a subdomain' do
        let(:source_hostname) { 'https://subdomain.github.com/path' }

        it 'normalizes the base URI and keeps the subdomain in the source_hostname' do
          expect(find_or_create_source_user.source_hostname).to eq('https://subdomain.github.com')
        end
      end
    end

    context 'when the placeholder user limit has been reached' do
      before do
        allow_next_instance_of(Import::PlaceholderUserLimit) do |limit|
          allow(limit).to receive(:exceeded?).and_return(true)
        end
      end

      it 'does not create any placeholder users and assigns the import user' do
        expect { find_or_create_source_user }
          .to change { Import::SourceUser.count }.by(1)
          .and not_change { User.count }

        new_import_source_user = Import::SourceUser.last

        expect(new_import_source_user.placeholder_user).to eq(import_user)
      end
    end

    context 'when ActiveRecord::RecordNotUnique exception is raised during the source user creation' do
      before do
        allow_next_instance_of(::Import::SourceUser) do |source_user|
          allow(source_user).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
        end
      end

      it 'raises DuplicatedSourceUserError' do
        expect { find_or_create_source_user }.to raise_error(described_class::DuplicatedSourceUserError)
      end
    end

    context 'when ActiveRecord::RecordInvalid exception because the placeholder user email or username is taken' do
      it 'rescue the exception and raises DuplicatedSourceUserError' do
        create(:user, email: 'user@example.com')
        user = build(:user, email: 'user@example.com').tap(&:valid?)
        allow(User).to receive(:new).and_return(user)

        expect { find_or_create_source_user }.to raise_error(described_class::DuplicatedSourceUserError)
      end
    end

    context 'when ActiveRecord::RecordInvalid exception raises for another reason' do
      it 'bubbles up the ActiveRecord::RecordInvalid exception' do
        user = build(:user, email: nil)
        allow(User).to receive(:new).and_return(user)

        expect { find_or_create_source_user }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when cache is true' do
      let(:cache) { true }

      it 'caches the created source user' do
        source_user = find_or_create_source_user

        expect(Gitlab::SafeRequestStore[:source_user_cache][source_user.source_user_identifier]).to eq(source_user)
      end
    end

    context 'when cache is false' do
      let(:cache) { false }

      it 'does not cache the created source user' do
        source_user = find_or_create_source_user

        expect(Gitlab::SafeRequestStore[:source_user_cache][source_user.source_user_identifier]).to eq(nil)
      end
    end
  end

  describe '#find_source_user' do
    let(:source_user_identifier) { existing_import_source_user.source_user_identifier }

    subject(:find_source_user) do
      described_class.new(
        namespace: namespace,
        import_type: import_type,
        source_hostname: source_hostname
      ).find_source_user(source_user_identifier)
    end

    it 'returns the existing source user' do
      expect(find_source_user).to eq(existing_import_source_user)
    end

    context 'when source_hostname has a path, and the source user record does not' do
      let(:source_hostname) { 'https://github.com/path' }

      it 'returns the existing source user' do
        expect(find_source_user).to eq(existing_import_source_user)
        expect(existing_import_source_user.source_hostname).to eq('https://github.com')
      end
    end

    context 'when source_hostname has a port, and the source user record does not' do
      let(:source_hostname) { 'https://github.com:8443' }

      it 'does not return the existing source user' do
        expect(find_source_user).to be_nil
      end
    end

    context 'when source_hostname has a subdomain, and the source user record does not' do
      let(:source_hostname) { 'https://subdomain.github.com' }

      it 'does not return the existing source user' do
        expect(find_source_user).to be_nil
      end
    end

    context 'when source_hostname scheme does not match' do
      let(:source_hostname) { 'http://github.com' }

      it 'does not return the existing source user' do
        expect(find_source_user).to be_nil
      end
    end

    context 'when namespace does not match' do
      let(:namespace) { create(:group) }

      it 'does not return the existing source user' do
        expect(find_source_user).to be_nil
      end
    end

    context 'when import_type does not match' do
      let(:import_type) { 'gitea' }

      it 'does not return the existing source user' do
        expect(find_source_user).to be_nil
      end
    end

    context 'when source user does not exist' do
      let(:source_user_identifier) { '999999' }

      it { is_expected.to be_nil }

      it 'does not cache the result and queries the database multiple times' do
        expect(::Import::SourceUser).to receive(:find_source_user).twice.and_call_original

        2.times do
          described_class.new(
            namespace: namespace,
            import_type: import_type,
            source_hostname: source_hostname
          ).find_source_user(source_user_identifier)
        end
      end
    end

    context 'when called multiple times' do
      it 'returns the same result' do
        expect(find_source_user).to eq(
          described_class.new(
            namespace: namespace,
            import_type: import_type,
            source_hostname: source_hostname
          ).find_source_user(source_user_identifier)
        )
      end

      it 'caches the result and does not query the database multiple times' do
        expect(::Import::SourceUser).to receive(:find_source_user).once.and_call_original

        2.times do
          described_class.new(
            namespace: namespace,
            import_type: import_type,
            source_hostname: source_hostname
          ).find_source_user(source_user_identifier)
        end
      end
    end
  end
end
