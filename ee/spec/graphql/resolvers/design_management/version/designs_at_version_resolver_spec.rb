# frozen_string_literal: true

require "spec_helper"

describe Resolvers::DesignManagement::Version::DesignsAtVersionResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  set(:issue) { create(:issue) }
  set(:project) { issue.project }

  set(:design_a) { create(:design, issue: issue) }
  set(:design_b) { create(:design, issue: issue) }
  set(:design_c) { create(:design, issue: issue) }
  set(:design_d) { create(:design, issue: issue) }

  set(:current_user) { create(:user) }
  let(:gql_context) { { current_user: current_user } }

  set(:first_version) do
    create(:design_version, issue: issue,
           created_designs: [design_a],
           modified_designs: [],
           deleted_designs: [])
  end
  set(:second_version) do
    create(:design_version, issue: issue,
           created_designs: [design_b, design_c, design_d],
           modified_designs: [design_a],
           deleted_designs: [])
  end
  set(:third_version) do
    create(:design_version, issue: issue,
           created_designs: [],
           modified_designs: [design_a],
           deleted_designs: [design_d])
  end

  let(:version) { third_version }
  let(:design) { design_a }

  let(:all_singular_args) do
    {
      design_at_version_id: global_id_of(dav(design)),
      design_id: global_id_of(design),
      filename: design.filename
    }
  end

  shared_examples 'a bad argument' do
    it 'raises an appropriate error' do
      err_class = ::Gitlab::Graphql::Errors::ArgumentError
      expect { resolve_objects }.to raise_error(err_class)
    end
  end

  before do
    enable_design_management
    project.add_developer(current_user)
  end

  describe ::Resolvers::DesignManagement::Version::DesignsAtVersionResolver.single do
    describe 'passing plural arguments' do
      context 'passing ids' do
        let(:args) { { ids: [design_a, design_b].map { |d| global_id_of(d) } } }

        it_behaves_like 'a bad argument'
      end

      context 'passing filenames' do
        let(:args) { { filenames: [design_a, design_b].map(&:filename) } }

        it_behaves_like 'a bad argument'
      end
    end

    describe 'passing combinations of arguments' do
      context 'passing no arguments' do
        let(:args) { {} }

        it_behaves_like 'a bad argument'
      end

      context 'passing all arguments' do
        let(:args) { all_singular_args }

        it_behaves_like 'a bad argument'
      end

      context 'passing any two arguments' do
        let(:args) { all_singular_args.slice(*all_singular_args.keys.sample(2)) }

        it_behaves_like 'a bad argument'
      end
    end

    %i[design_at_version_id design_id filename].each do |arg|
      describe "passing #{arg}" do
        let(:args) { all_singular_args.slice(arg) }

        it "finds the design" do
          expect(resolve_objects).to eq(dav(design))
        end
      end
    end

    describe 'attempting to retrieve an object not visible at this version' do
      let(:design) { design_d }

      %i[design_at_version_id design_id filename].each do |arg|
        describe "passing #{arg}" do
          let(:args) { all_singular_args.slice(arg) }

          it "does not find the design" do
            expect(resolve_objects).to be_nil
          end
        end
      end
    end
  end

  describe "#resolve" do
    let(:args) { {} }

    context "when the user cannot see designs" do
      let(:gql_context) { { current_user: create(:user) } }

      it "returns nothing" do
        expect(resolve_objects).to be_empty
      end
    end

    context "for the current version" do
      it "returns all designs visible at that version" do
        expect(resolve_objects).to contain_exactly(dav(design_a), dav(design_b), dav(design_c))
      end
    end

    context "for a previous version with more objects" do
      let(:version) { second_version }

      it "returns objects that were later deleted" do
        expect(resolve_objects).to contain_exactly(dav(design_a), dav(design_b), dav(design_c), dav(design_d))
      end
    end

    context "for a previous version with fewer objects" do
      let(:version) { first_version }

      it "does not return objects that were later created" do
        expect(resolve_objects).to contain_exactly(dav(design_a))
      end
    end

    describe "filtering" do
      describe "by filename" do
        let(:red_herring) { create(:design, issue: create(:issue, project: project)) }
        let(:args) { { filenames: [design_b.filename, red_herring.filename] } }

        it "resolves to just the relevant design" do
          create(:design, issue: create(:issue, project: project), filename: design_b.filename)

          expect(resolve_objects).to contain_exactly(dav(design_b))
        end
      end

      describe "by id" do
        let(:red_herring) { create(:design, issue: create(:issue, project: project)) }
        let(:args) { { ids: [design_a, red_herring].map { |x| global_id_of(x) } } }

        it "resolves to just the relevant design, ignoring objects on other issues" do
          expect(resolve_objects).to contain_exactly(dav(design_a))
        end
      end

      describe 'passing singular arguments' do
        %i[design_at_version_id design_id filename].each do |k|
          context "passing #{k}" do
            let(:args) { all_singular_args.slice(k) }

            it_behaves_like 'a bad argument'
          end
        end
      end
    end
  end

  def resolve_objects
    resolve(described_class, obj: version, args: args, ctx: gql_context)
  end

  def dav(design)
    build(:design_at_version, design: design, version: version)
  end
end
