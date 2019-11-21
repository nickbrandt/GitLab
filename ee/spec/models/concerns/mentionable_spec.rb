# frozen_string_literal: true

require 'spec_helper'

describe Epic, 'Mentionable' do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in descritpion', :epic
    it_behaves_like 'mentions in notes', :epic do
      let(:note) { create(:note_on_epic) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :epic do
      let(:note) { create(:note_on_epic) }
      let(:mentionable) { note.noteable }
    end
  end
end

describe Note, 'Mentionable' do
  describe '#store_mentions!' do
    it_behaves_like 'mentions in notes', :design do
      let(:note) { create(:diff_note_on_design) }
      let(:mentionable) { note.noteable }
    end
  end

  describe 'load mentions' do
    it_behaves_like 'load mentions from DB', :design do
      let(:note) { create(:diff_note_on_design) }
      let(:mentionable) { note.noteable }
    end
  end
end
