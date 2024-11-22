# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::PackagesForBatchFinder, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group, reporters: [user]) }
  let_it_be(:project2) { create(:project, group: group) }

  let_it_be(:p1) { create(:npm_package, project: project) }
  let_it_be(:p2) { create(:npm_package, project: project2) }
  let_it_be(:p3) { create(:npm_package, project: project) }
  let_it_be(:package_name) { p1.name }
  let_it_be(:batch) { ::Packages::Package.where(id: [p1.id, p2.id]) }
  let(:finder) { described_class.new(user, group, { packages: batch }) }

  describe '#execute' do
    subject(:result) { finder.execute }

    shared_examples 'searches for packages' do
      it { is_expected.to contain_exactly(p1) }
    end

    context 'with an empty batch' do
      let(:batch) { ::Packages::Package.none }

      it { is_expected.to be_empty }
    end

    context 'with a group' do
      before_all do
        project.add_reporter(user)
      end

      it_behaves_like 'searches for packages'
      it_behaves_like 'avoids N+1 database queries in the package registry'

      context 'when user is a reporter of both projects' do
        before_all do
          project2.add_reporter(user)
        end

        it { is_expected.to contain_exactly(p1, p2) }

        context 'when the second project has the package registry disabled' do
          before_all do
            project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            project2.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC,
              package_registry_access_level: 'disabled', packages_enabled: false)
          end

          it_behaves_like 'searches for packages'
        end
      end
    end
  end
end
