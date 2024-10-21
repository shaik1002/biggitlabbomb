# frozen_string_literal: true

RSpec.shared_examples 'desired sharding key backfill job' do
  let(:known_cross_joins) do
    {
      sbom_occurrences_vulnerabilities: {
        sbom_occurrences: 'https://gitlab.com/groups/gitlab-org/-/epics/14116#identified-cross-joins'
      },
      vulnerability_finding_evidences: {
        vulnerability_occurrences: 'https://gitlab.com/groups/gitlab-org/-/epics/14116#identified-cross-joins'
      },
      vulnerability_finding_links: {
        vulnerability_occurrences: 'https://gitlab.com/groups/gitlab-org/-/epics/14116#identified-cross-joins'
      },
      vulnerability_finding_signatures: {
        vulnerability_occurrences: 'https://gitlab.com/groups/gitlab-org/-/epics/14116#identified-cross-joins'
      },
      vulnerability_flags: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/473014'
      },
      dast_site_validations: { dast_site_tokens: 'https://gitlab.com/gitlab-org/gitlab/-/issues/474985' }
    }
  end

  let!(:connection) { table(batch_table).connection }
  let!(:starting_id) { table(batch_table).pluck(:id).min }
  let!(:end_id) { table(batch_table).pluck(:id).max }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: connection,
      job_arguments: [
        backfill_column,
        backfill_via_table,
        backfill_via_column,
        backfill_via_foreign_key
      ]
    )
  end

  it 'performs without error' do
    expect { migration.perform }.not_to raise_error
  end

  it 'constructs a valid query' do
    query = migration.construct_query(sub_batch: table(batch_table).all)

    if known_cross_joins.dig(batch_table, backfill_via_table).present?
      ::Gitlab::Database.allow_cross_joins_across_databases(
        url: known_cross_joins[batch_table][backfill_via_table]
      ) do
        expect { connection.execute(query) }.not_to raise_error
      end
    else
      expect { connection.execute(query) }.not_to raise_error
    end
  end
end
