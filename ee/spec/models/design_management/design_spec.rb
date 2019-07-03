# frozen_string_literal: true

require 'rails_helper'

describe DesignManagement::Design do
  describe 'relations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to have_many(:design_versions) }
    it { is_expected.to have_many(:versions) }
    it { is_expected.to have_many(:notes).dependent(:delete_all) }
  end

  describe 'validations' do
    subject(:design) { build(:design) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:filename) }
    it { is_expected.to validate_uniqueness_of(:filename).scoped_to(:issue_id) }

    it "validates that the file is an image" do
      design.filename = "thing.txt"

      expect(design).not_to be_valid
      expect(design.errors[:filename].first)
        .to match /Only these extensions are supported/
    end
  end

  describe 'scopes' do
    describe '.visible_at_version' do
      let!(:design1) { create(:design, :with_file, versions_count: 1) }
      let!(:design2) { create(:design, :with_file, versions_count: 1) }
      let(:first_version) { DesignManagement::Version.ordered.last }
      let(:second_version) { DesignManagement::Version.ordered.first }

      it 'returns just designs that existed at that version' do
        expect(described_class.visible_at_version(first_version)).to eq([design1])
        expect(described_class.visible_at_version(second_version)).to contain_exactly(design1, design2)
      end

      it 'can be passed either a DesignManagement::Version or an ID' do
        [first_version, first_version.id].each do |arg|
          expect(described_class.visible_at_version(arg)).to eq([design1])
        end
      end
    end
  end

  describe "#new_design?" do
    set(:versions) { create(:design_version) }
    set(:design) { create(:design, versions: [versions]) }

    it "is false when there are versions" do
      expect(design.new_design?).to be_falsy
    end

    it "is true when there are no versions" do
      expect(build(:design).new_design?).to be_truthy
    end

    it "does not cause extra queries when versions are loaded" do
      design.versions.map(&:id)

      expect { design.new_design? }.not_to exceed_query_limit(0)
    end

    it "causes a single query when there versions are not loaded" do
      design.reload

      expect { design.new_design? }.not_to exceed_query_limit(1)
    end
  end

  describe "#full_path" do
    it "builds the full path for a design" do
      design = build(:design, filename: "hello.jpg")
      expected_path = "#{DesignManagement.designs_directory}/issue-#{design.issue.iid}/hello.jpg"

      expect(design.full_path).to eq(expected_path)
    end
  end

  describe '#diff_refs' do
    it "builds diff refs based on the first commit and it's for the design" do
      design = create(:design, :with_file, versions_count: 3)

      expect(design.diff_refs.base_sha).to eq(design.versions.ordered.second.sha)
      expect(design.diff_refs.head_sha).to eq(design.versions.ordered.first.sha)
    end

    it 'builds diff refs based on the empty tree if there was only one version' do
      design = create(:design, :with_file, versions_count: 1)

      expect(design.diff_refs.base_sha).to eq(Gitlab::Git::BLANK_SHA)
      expect(design.diff_refs.head_sha).to eq(design.diff_refs.head_sha)
    end
  end

  describe '#repository' do
    it 'is a design repository' do
      design = build(:design)

      expect(design.repository).to be_a(DesignManagement::Repository)
    end
  end
end
