# frozen_string_literal: true
require 'spec_helper'

describe DiffNote do
  describe 'Validations' do
    it 'allows diffnotes on designs' do
      diff_note = build(:diff_note_on_design)

      expect(diff_note).to be_valid
    end
  end

  context 'diff files' do
    let(:design) { create(:design, :with_file, versions_count: 2) }
    let(:diff_note) { create(:diff_note_on_design, noteable: design, project: design.project) }

    describe '#latest_diff_file' do
      it 'does not return a diff file' do
        expect(diff_note.latest_diff_file).to be_nil
      end
    end

    describe '#diff_file' do
      it 'does not return a diff file' do
        expect(diff_note.diff_file).to be_nil
      end
    end
  end
end
