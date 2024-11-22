# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildSourceFinder, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline, source: "push") }

  let_it_be(:build_non_relevant) { create(:ci_build, pipeline: pipeline, name: "unique-name") }
  let_it_be(:old_build) { create(:ci_build, pipeline: pipeline, name: "build1") }
  let_it_be(:old_middle_build) { create(:ci_build, pipeline: pipeline, name: "build2") }
  let_it_be(:middle_build) { create(:ci_build, pipeline: pipeline, name: "build3") }
  let_it_be(:middle_new_build) { create(:ci_build, pipeline: pipeline, name: "build4") }
  let_it_be(:new_build) { create(:ci_build, pipeline: pipeline, name: "build5") }

  let_it_be(:old_build_source) { create(:ci_build_source, build: old_build, source: :scan_execution_policy) }
  let_it_be(:old_middle_build_source) do
    create(:ci_build_source, build: old_middle_build, source: :pipeline_execution_policy, pipeline_source: :trigger)
  end

  let_it_be(:middle_build_source) { create(:ci_build_source, build: middle_build, source: :scan_execution_policy) }
  let_it_be(:middle_new_build_source) do
    create(:ci_build_source, build: middle_new_build, source: :pipeline_execution_policy, pipeline_source: :push)
  end

  let_it_be(:new_build_source) { create(:ci_build_source, build: new_build, source: :scan_execution_policy) }

  describe "#execute" do
    let(:main_relation) { Ci::Build.all }
    let(:sources) { ["scan_execution_policy"] }
    let(:before) { nil }
    let(:after) { nil }
    let(:asc) { nil }
    let(:invert_ordering) { false }

    subject(:build_source_finder) do
      described_class.new(
        relation: main_relation,
        sources: sources,
        project: pipeline.project,
        params: {
          before: before, after: after, asc: asc,
          invert_ordering: invert_ordering
        }
      ).execute
    end

    it 'filters by source in desc order' do
      expect(build_source_finder)
        .to eq([new_build, middle_build, old_build])
    end

    context 'when no source is passed in' do
      let(:sources) { [] }

      it 'does not filter by source' do
        expect(build_source_finder.count).to eq(6)
      end
    end

    context 'with pipeline source query' do
      let(:sources) { ["trigger"] }

      it 'returns build from given pipeline source' do
        expect(build_source_finder)
          .to eq([old_middle_build])
      end
    end

    context 'with multiple source query' do
      let(:sources) { %w[scan_execution_policy push] }

      it 'returns builds from any of the given sources' do
        expect(build_source_finder)
          .to eq([new_build, middle_new_build, middle_build, old_build])
      end
    end

    describe 'argument errors' do
      context 'when relation is not Ci::Build' do
        let(:main_relation) { Ci::Bridge.all }

        it 'raises argument error for relation' do
          expect { build_source_finder.execute }.to raise_error(ArgumentError, 'Only Ci::Builds are source searchable')
        end
      end

      context 'when relation is using offset' do
        it 'raises argument error for params' do
          expect do
            described_class.new(
              relation: main_relation.offset(1),
              sources: sources,
              project: pipeline.project,
              params: {}
            )
            .execute
          end.to raise_error(ArgumentError, 'Offset Pagination is not supported')
        end
      end
    end

    context 'with before param' do
      let(:before) { old_middle_build.id }

      it 'returns builds newer than old middle build' do
        expect(build_source_finder)
          .to eq([new_build, middle_build])
      end

      context 'with asc param' do
        let(:asc) { true }

        it 'returns only the builds in asc order' do
          expect(build_source_finder)
            .to eq([middle_build, new_build])
        end
      end
    end

    context 'with after param' do
      let(:after) { middle_new_build.id }

      it 'returns builds older than middle new build' do
        expect(build_source_finder)
          .to eq([middle_build, old_build])
      end

      context 'with asc param' do
        let(:asc) { true }

        it 'returns build before cursor in asc order' do
          expect(build_source_finder)
            .to eq([old_build, middle_build])
        end
      end
    end

    context 'with asc param' do
      let(:asc) { true }

      it 'returns the records in ascending order' do
        expect(build_source_finder).to eq([old_build, middle_build, new_build])
      end
    end
  end
end
