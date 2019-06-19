# frozen_string_literal: true
require 'spec_helper'

describe Mutations::DesignManagement::Upload do
  include DesignManagementTestHelpers

  let(:issue) { create(:issue) }
  let(:user) { issue.author }
  let(:project) { issue.project }

  subject(:mutation) do
    described_class.new(object: nil, context: { current_user: user })
  end

  describe "#resolve" do
    let(:files) { [fixture_file_upload('spec/fixtures/dk.png')] }

    subject(:resolve) do
      mutation.resolve(project_path: project.full_path, iid: issue.iid, files: files)
    end

    shared_examples "resource not available" do
      it "raises an error" do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context "when the feature is not available" do
      it_behaves_like "resource not available"
    end

    context "when the feature is available" do
      before do
        enable_design_management
      end

      context "when the user is not allowed to upload designs" do
        let(:user) { create(:user) }

        it_behaves_like "resource not available"
      end

      context "a valid design" do
        it "returns the updated designs" do
          expect(resolve[:errors]).to eq []
          expect(resolve[:designs].map(&:filename)).to contain_exactly("dk.png")
        end
      end

      context "context when passing an invalid project" do
        let(:project) { build(:project) }

        it_behaves_like "resource not available"
      end

      context "context when passing an invalid issue" do
        let(:issue) { build(:issue) }

        it_behaves_like "resource not available"
      end

      context "when creating designs causes errors" do
        before do
          fake_service = double(::DesignManagement::SaveDesignsService)

          allow(fake_service).to receive(:execute).and_return(status: :error, message: "Something failed")
          allow(::DesignManagement::SaveDesignsService).to receive(:new).and_return(fake_service)
        end

        it "wraps the errors" do
          expect(resolve[:errors]).to eq(["Something failed"])
          expect(resolve[:designs]).to eq([])
        end
      end
    end
  end
end
