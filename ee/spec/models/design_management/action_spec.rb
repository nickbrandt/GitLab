# frozen_string_literal: true
require 'spec_helper'

describe DesignManagement::Action do
  describe 'relations' do
    it { is_expected.to belong_to(:design) }
    it { is_expected.to belong_to(:version) }
  end

  describe 'scopes' do
    describe '.most_recent' do
      set(:design_a) { create(:design) }
      set(:design_b) { create(:design) }
      set(:design_c) { create(:design) }

      let(:designs) { [design_a, design_b, design_c] }

      before(:all) do
        create(:design_version, designs: [design_a, design_b, design_c])
        create(:design_version, designs: [design_a, design_b])
        create(:design_version, designs: [design_a])
      end

      it 'finds the correct version for each design' do
        dvs = described_class.where(design: designs)

        expected = designs
          .map(&:id)
          .zip(dvs.order("version_id DESC").pluck(:version_id).uniq)

        actual = dvs.most_recent.map { |dv| [dv.design_id, dv.version_id] }

        expect(actual).to eq(expected)
      end
    end

    describe '.up_to_version' do
      set(:issue) { create(:issue) }
      set(:design_a) { create(:design, issue: issue) }
      set(:design_b) { create(:design, issue: issue) }

      # let bindings are not available in before(:all) contexts,
      # so we need to redefine the array on each construction.
      set(:oldest) { create(:design_version, designs: [design_a, design_b]) }
      set(:middle) { create(:design_version, designs: [design_a, design_b]) }
      set(:newest) { create(:design_version, designs: [design_a, design_b]) }

      subject { described_class.where(design: issue.designs).up_to_version(version) }

      context 'the version is nil' do
        let(:version) { nil }

        it 'returns all design_versions' do
          is_expected.to have_attributes(size: 6)
        end
      end

      context 'the version is the most current' do
        let(:version) { newest }

        it { is_expected.to have_attributes(size: 6) }
      end

      context 'the version is the oldest' do
        let(:version) { oldest }

        it { is_expected.to have_attributes(size: 2) }
      end

      context 'the version is the middle one' do
        let(:version) { middle }

        it { is_expected.to have_attributes(size: 4) }
      end
    end
  end
end
