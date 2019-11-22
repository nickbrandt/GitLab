# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Tag, type: :model do
  let!(:project) { create(:project) }
  let!(:package) { create(:npm_package, version: '1.0.2', project: project, updated_at: 3.days.ago) }

  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:tags) }
  end

  describe 'validations' do
    subject { create(:packages_tag) }

    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '.for_packages' do
    let(:package2) { create(:package, project: project, updated_at: 2.days.ago) }
    let(:package3) { create(:package, project: project, updated_at: 1.day.ago) }
    let(:tags_limit) { Packages::Tag::TAGS_LIMIT }
    let!(:tag1) { create(:packages_tag, package: package) }
    let!(:tag2) { create(:packages_tag, package: package2) }
    let!(:tag3) { create(:packages_tag, package: package3) }

    subject { described_class.for_packages(project.packages, tags_limit) }

    it { is_expected.to match_array([tag1, tag2, tag3]) }

    context 'with too many tags' do
      let(:tags_limit) { 2 }

      it { is_expected.to match_array([tag2, tag3]) }
    end
  end
end
