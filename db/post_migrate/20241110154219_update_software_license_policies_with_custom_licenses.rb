# frozen_string_literal: true

class UpdateSoftwareLicensePoliciesWithCustomLicenses < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 100

  def up
    each_batch_range('software_license_policies', of: BATCH_SIZE) do |min, max|
      execute <<~SQL
          UPDATE software_license_policies
          SET software_license_id = NULL,
          custom_software_license_id = custom_software_licenses.id
        FROM
            custom_software_licenses
            JOIN software_licenses ON custom_software_licenses.name = software_licenses.name
        WHERE
            software_licenses.spdx_identifier IS NULL
            AND custom_software_licenses.project_id = software_license_policies.project_id
            AND software_licenses.id = software_license_policies.software_license_id
            AND software_license_policies.id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # no-op
  end
end
