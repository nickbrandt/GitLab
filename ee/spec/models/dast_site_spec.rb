# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSite, type: :model do
  subject { create(:dast_site) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:dast_site_profiles) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:url).scoped_to(:project_id) }
    it { is_expected.to validate_presence_of(:project_id) }

    context 'when the url is not public' do
      subject { build(:dast_site, url: 'http://127.0.0.1') }

      it 'is not valid' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.full_messages).to include('Url is blocked: Requests to localhost are not allowed')
      end
    end
  end
end
