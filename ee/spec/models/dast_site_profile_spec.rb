# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteProfile, type: :model do
  subject { create(:dast_site_profile) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:dast_site) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:dast_site_id) }

    context 'when the project_id and dast_site.project_id do not match' do
      let(:project) { create(:project) }
      let(:dast_site) { create(:dast_site) }

      subject { build(:dast_site_profile, project: project, dast_site: dast_site) }

      it 'is not valid' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.full_messages).to include('Project does not match dast_site.project')
      end
    end
  end
end
