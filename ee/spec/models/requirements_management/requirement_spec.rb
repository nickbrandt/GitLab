# frozen_string_literal: true

require 'spec_helper'

describe RequirementsManagement::Requirement do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    subject { build(:requirement) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    subject { build(:requirement) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }

    it { is_expected.to validate_length_of(:title).is_at_most(::Issuable::TITLE_LENGTH_MAX) }
    it { is_expected.to validate_length_of(:title_html).is_at_most(::Issuable::TITLE_HTML_LENGTH_MAX) }
  end

  describe 'scopes' do
    describe '.counts_by_state' do
      let_it_be(:opened) { create(:requirement, project: project, state: :opened) }
      let_it_be(:archived) { create(:requirement, project: project, state: :archived) }

      subject { described_class.counts_by_state }

      it { is_expected.to contain_exactly(['archived', 1], ['opened', 1]) }
    end
  end
end
