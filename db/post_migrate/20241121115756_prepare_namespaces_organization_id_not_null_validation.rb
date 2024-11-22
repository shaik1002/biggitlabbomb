# frozen_string_literal: true

class PrepareNamespacesOrganizationIdNotNullValidation < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  CONSTRAINT_NAME = 'check_2eae3bdf93'

  def up
    prepare_async_check_constraint_validation :namespaces, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :namespaces, name: CONSTRAINT_NAME
  end
end
