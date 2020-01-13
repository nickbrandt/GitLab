# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::DesignManagement::VersionResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  before do
    enable_design_management
  end

  describe "#resolve" do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:project) { issue.project }
    let_it_be(:first_version) { create(:design_version) }
    let_it_be(:first_design) { create(:design, issue: issue, versions: [first_version]) }
    let(:current_user) { create(:user) }

    before do
      project.add_developer(current_user)
    end

    context "for a design collection" do
      let(:collection) { DesignManagement::DesignCollection.new(issue) }

      it "returns the ordered versions" do
        second_version = create(:design_version)
        create(:design, issue: issue, versions: [second_version])

        expect(resolve_versions(collection)).to eq([second_version, first_version])
      end
    end

    context "for a design" do
      it "returns the versions" do
        expect(resolve_versions(first_design)).to eq([first_version])
      end
    end

    context "when the user is anonymous" do
      let(:current_user) { nil }

      it "returns nothing" do
        expect(resolve_versions(first_design)).to be_empty
      end
    end

    context "when the user cannot see designs" do
      it "returns nothing" do
        expect(resolve_versions(first_design, {}, current_user: create(:user))).to be_empty
      end
    end
  end

  def resolve_versions(obj, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: obj, args: args, ctx: context)
  end
end
