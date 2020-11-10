# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::RequirementsManagement::ImportCsvRequirements do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:mutation) do
    described_class.new(object: nil, context: { current_user: user }, field: nil)
  end

  describe "#resolve" do
    let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

    subject(:resolve) do
      mutation.resolve(project_path: project.full_path, file: file)
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
        stub_licensed_features(requirements: true)
      end

      context "when the user is not allowed to create requirements" do
        before do
          project.add_guest(user)
        end

        it_behaves_like "resource not available"
      end

      context 'when user can create requirements' do
        before do
          project.add_reporter(user)
        end

        context "with a valid CSV file" do
          it "successfully import requirements" do
            expect { resolve }.to change(project.requirements, :count).by(3)
            expect(resolve[:imported_count]).to eq(3)
            expect(resolve[:errors]).to eq []
          end
        end

        context 'when the upload fails' do
          it "shows file upload error" do
            expect_next_instance_of(UploadService) do |upload_service|
              expect(upload_service).to receive(:execute).and_return(nil)
            end

            expect(resolve[:errors]).to eq(['File upload error.'])
          end
        end

        context 'when the CSV file format is incorrect' do
          let(:file) { fixture_file_upload('spec/fixtures/csv_no_headers.csv') }

          it "shows parse error" do
            expect(resolve[:imported_count]).to eq(0)
            expect(resolve[:errors]).to eq(['Error parsing CSV file. Please make sure it has the correct format.'])
          end
        end

        context 'when some requirements failed to be created' do
          let(:file) { fixture_file_upload('spec/fixtures/csv_tab.csv') }

          it "shows line errors" do
            expect(resolve[:imported_count]).to eq(2)
            expect(resolve[:errors]).to eq(['Errors found on line number: 3.'])
          end
        end
      end
    end
  end
end
