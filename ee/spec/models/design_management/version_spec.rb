# frozen_string_literal: true
require 'rails_helper'

describe DesignManagement::Version do
  describe 'relations' do
    it { is_expected.to have_many(:design_versions) }
    it { is_expected.to have_many(:designs).through(:design_versions) }

    it 'constrains the designs relation correctly' do
      design = create(:design)
      version = create(:design_version)

      version.designs << design

      expect { version.designs << design }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows adding multiple versions to a single design' do
      design = create(:design)
      versions = create_list(:design_version, 2)

      expect { versions.each { |v| design.versions << v } }
        .not_to raise_error
    end
  end

  describe 'validations' do
    subject(:design_version) { build(:design_version) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:sha) }
    it { is_expected.to validate_uniqueness_of(:sha).case_insensitive }
  end

  describe "scopes" do
    let(:version_1) { create(:design_version) }
    let(:version_2) { create(:design_version) }

    describe ".for_designs" do
      it "only returns versions related to the specified designs" do
        _other_version = create(:design_version)
        designs = [create(:design, versions: [version_1]),
                   create(:design, versions: [version_2])]

        expect(described_class.for_designs(designs))
          .to contain_exactly(version_1, version_2)
      end
    end

    describe '.earlier_or_equal_to' do
      it 'only returns versions created earlier or later than the given version' do
        expect(described_class.earlier_or_equal_to(version_1)).to eq([version_1])
        expect(described_class.earlier_or_equal_to(version_2)).to contain_exactly(version_1, version_2)
      end

      it 'can be passed either a DesignManagement::Design or an ID' do
        [version_1, version_1.id].each do |arg|
          expect(described_class.earlier_or_equal_to(arg)).to eq([version_1])
        end
      end
    end
  end

  describe ".bulk_create" do
    it "creates a version and links it to multiple designs" do
      designs = create_list(:design, 2)

      version = described_class.create_for_designs(designs, "abc")

      expect(version.designs).to contain_exactly(*designs)
    end
  end

  describe "#issue" do
    it "gets the issue for the linked design" do
      version = create(:design_version)
      design = create(:design, versions: [version])

      expect(version.issue).to eq(design.issue)
    end
  end
end
