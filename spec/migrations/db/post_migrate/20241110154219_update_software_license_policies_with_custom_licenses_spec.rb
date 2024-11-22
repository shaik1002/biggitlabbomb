# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateSoftwareLicensePoliciesWithCustomLicenses, migration: :gitlab_main, feature_category: :security_policy_management do
  let(:software_licenses_table) { table(:software_licenses) }
  let(:custom_software_licenses_table) { table(:custom_software_licenses) }
  let(:software_license_policies_table) { table(:software_license_policies) }
  let(:projects_table) { table(:projects) }
  let(:namespace_table) { table(:namespaces) }

  let!(:namespace) { namespace_table.create!(name: 'namespace', path: 'namespace') }
  let!(:project) { projects_table.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  describe '#up' do
    context 'when there are no software licenses policies linked to software licenses without spdx_identifier' do
      let!(:software_license_with_spdx) { software_licenses_table.create!(name: 'MIT License', spdx_identifier: 'MIT') }
      let!(:software_license_policy) do
        software_license_policies_table.create!(project_id: project.id,
          software_license_id: software_license_with_spdx.id)
      end

      it 'does not update the software_license_id' do
        expect(software_license_policy.software_license_id).to eq(software_license_with_spdx.id)

        migrate!

        expect(software_license_policy.reload.software_license_id).to eq(software_license_with_spdx.id)
      end
    end

    context 'when there are software licenses policies linked to software licenses without spdx_identifier' do
      let(:custom_license_name) { 'Custom License' }
      let!(:software_license_without_spdx) { software_licenses_table.create!(name: custom_license_name) }
      let!(:custom_software_license) do
        custom_software_licenses_table.create!(name: custom_license_name, project_id: project.id)
      end

      let!(:software_license_policy) do
        software_license_policies_table.create!(project_id: project.id,
          software_license_id: software_license_without_spdx.id)
      end

      it 'does update the software_license_id and custom_software_license_id' do
        expect(software_license_policy.software_license_id).to eq(software_license_without_spdx.id)
        expect(software_license_policy.custom_software_license_id).to be_nil

        migrate!

        software_license_policy.reload

        expect(software_license_policy.software_license_id).to be_nil
        expect(software_license_policy.custom_software_license_id).to eq(custom_software_license.id)
      end

      context 'when the software license without spdx is linked to software licenses policies of different projects' do
        let!(:other_namespace) { namespace_table.create!(name: 'other namespace', path: 'other namespace') }
        let!(:other_project) do
          projects_table.create!(namespace_id: other_namespace.id, project_namespace_id: other_namespace.id)
        end

        let!(:other_custom_software_license) do
          custom_software_licenses_table.create!(name: custom_license_name, project_id: other_project.id)
        end

        let!(:other_software_license_policy) do
          software_license_policies_table.create!(project_id: other_project.id,
            software_license_id: software_license_without_spdx.id)
        end

        it 'does update the software_license_id and custom_software_license_id for both software license policies' do
          expect(software_license_policy.software_license_id).to eq(software_license_without_spdx.id)
          expect(software_license_policy.custom_software_license_id).to be_nil

          expect(other_software_license_policy.software_license_id).to eq(software_license_without_spdx.id)
          expect(other_software_license_policy.custom_software_license_id).to be_nil

          migrate!
          software_license_policy.reload
          other_software_license_policy.reload

          expect(software_license_policy.software_license_id).to be_nil
          expect(software_license_policy.custom_software_license_id).to eq(custom_software_license.id)

          expect(other_software_license_policy.software_license_id).to be_nil
          expect(other_software_license_policy.custom_software_license_id).to eq(other_custom_software_license.id)
        end
      end
    end
  end
end
