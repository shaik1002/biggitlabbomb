# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::SystemNoteFacade, feature_category: :team_planning do
  let(:note) { instance_double(Note, system?: is_system_note, note: note_content, system_note_metadata: metadata) }
  let(:metadata) { instance_double(SystemNoteMetadata, cross_reference_types: cross_reference_types, action: action) }
  let(:facade) { described_class.new(note) }
  let(:is_system_note) { true }
  let(:note_content) { "cross reference content" }
  let(:cross_reference_types) { %w[cross_reference] }
  let(:action) { 'cross_reference' }

  describe '#system_note_with_references?' do
    subject(:system_note_with_references?) { facade.system_note_with_references? }

    context 'when the note is not a system note' do
      let(:is_system_note) { false }

      it { is_expected.to be_nil }
    end

    context 'when the note is a system note' do
      let(:is_system_note) { true }

      context 'when force_cross_reference_regex_check? returns true' do
        before do
          allow(facade).to receive(:force_cross_reference_regex_check?).and_return(true)
          allow(note).to receive(:matches_cross_reference_regex?).and_return(matches_cross_reference_regex)
        end

        context 'and note matches the cross-reference regex' do
          let(:matches_cross_reference_regex) { true }

          it { is_expected.to be(true) }
        end

        context 'and note does not match the cross-reference regex' do
          let(:matches_cross_reference_regex) { false }

          it { is_expected.to be(false) }
        end
      end

      context 'when force_cross_reference_regex_check? returns false' do
        before do
          allow(facade).to receive(:force_cross_reference_regex_check?).and_return(false)
        end

        it 'calls ::SystemNotes::IssuablesService.cross_reference?' do
          expect(::SystemNotes::IssuablesService).to receive(:cross_reference?).with(note_content)

          system_note_with_references?
        end

        context 'when cross_reference? returns true' do
          before do
            allow(::SystemNotes::IssuablesService).to receive(:cross_reference?).with(note_content).and_return(true)
          end

          it { is_expected.to be(true) }
        end

        context 'when cross_reference? returns false' do
          before do
            allow(::SystemNotes::IssuablesService).to receive(:cross_reference?).with(note_content).and_return(false)
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end

  describe '#force_cross_reference_regex_check?' do
    subject { facade.send(:force_cross_reference_regex_check?) }

    context 'when metadata cross_reference_types include the action' do
      it { is_expected.to be(true) }
    end

    context 'when metadata cross_reference_types do not include the action' do
      let(:cross_reference_types) { %w[other_action] }

      it { is_expected.to be(false) }
    end

    context 'when system_note_metadata is nil' do
      let(:metadata) { nil }

      it { is_expected.to be_nil }
    end
  end
end
