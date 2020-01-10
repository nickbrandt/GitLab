# frozen_string_literal: true

require "spec_helper"

describe Resolvers::DesignManagement::DesignResolver do
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
    let_it_be(:current_user) { create(:user) }

    before do
      project.add_developer(current_user)
    end

    context "when the user cannot see designs" do
      it "returns nothing" do
        expect(resolve_designs(issue.design_collection, {}, current_user: create(:user))).to be_empty
      end
    end

    context "for a design collection" do
      it "returns designs" do
        expect(resolve_designs(issue.design_collection, {}, current_user: current_user)).to contain_exactly(first_design)
      end

      it "returns all designs" do
        second_version = create(:design_version)
        second_design = create(:design, issue: issue, versions: [second_version])

        expect(resolve_designs(issue.design_collection, {}, current_user: current_user)).to contain_exactly(first_design, second_design)
      end
    end
  end

  def resolve_designs(obj, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: obj, args: args, ctx: context)
  end
end
