# frozen_string_literal: true
require "spec_helper"

describe DesignManagement::SaveDesignsService do
  let(:issue) { create(:issue, project: project) }
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:files) { [fixture_file_upload("spec/fixtures/rails_sample.jpg")] }
  let(:design_repository) { EE::Gitlab::GlRepository::DESIGN.repository_accessor.call(project) }
  let(:design_collection) { DesignManagement::DesignCollection.new(issue) }

  subject(:service) { described_class.new(project, user, issue: issue, files: files) }

  shared_examples "a service error" do
    it "returns an error", :aggregate_failures do
      expect(service.execute).to match(a_hash_including(status: :error))
    end
  end

  describe "#execute" do
    context "when the feature is not available" do
      before do
        stub_licensed_features(design_management: false)
      end

      it_behaves_like "a service error"
    end

    context "when the feature is available" do
      before do
        stub_licensed_features(design_management: true)
      end

      context "when LFS is not enabled" do
        it_behaves_like "a service error"
      end

      context "when LFS is enabled" do
        before do
          allow(project).to receive(:lfs_enabled?).and_return(true)
        end

        it "creates a design repository when it didn't exist" do
          repository_exists = -> do
            # Expire the memoized value as the service creates it's own instance
            design_repository.expire_exists_cache
            design_repository.exists?
          end

          expect { service.execute }.to change { repository_exists.call }.from(false).to(true)
        end

        it "creates a nice commit in the repository" do
          service.execute

          commit = design_repository.commit # Get the HEAD

          expect(commit).not_to be_nil
          expect(commit.author).to eq(user)
          expect(commit.message).to include("rails_sample.jpg")
        end

        it "creates a design & a version for the filename if it did not exist" do
          expect(issue.designs.size).to eq(0)

          updated_designs = service.execute[:designs]

          expect(updated_designs.size).to eq(1)
          expect(updated_designs.first.versions.size).to eq(1)
        end

        context "when the `store_designs_in_lfs` feature is enabled" do
          before do
            stub_feature_flags(store_designs_in_lfs: true)

            expect_next_instance_of(Lfs::FileTransformer) do |transformer|
              expect(transformer).to receive(:lfs_file?).and_return(true)
            end
          end

          it "saves the design to LFS" do
            expect { service.execute }.to change { LfsObject.count }.by(1)
          end

          it "saves the repository_type of the LfsObjectsProject as design" do
            expect do
              service.execute
            end.to change { project.lfs_objects_projects.count }.from(0).to(1)

            expect(project.lfs_objects_projects.first.repository_type).to eq("design")
          end
        end

        context "when the `store_designs_in_lfs` feature is not enabled" do
          before do
            stub_feature_flags(store_designs_in_lfs: false)
          end

          it "does not save the design to LFS" do
            expect { service.execute }.not_to change { LfsObject.count }
          end
        end

        context "when a design already exists" do
          before do
            # This makes sure the file is created in the repository.
            # otherwise we"d have a database & repository that are not in sync.
            service.execute
          end

          it "creates a new version for the existing design and updates the file" do
            expect(issue.designs.size).to eq(1)
            expect(DesignManagement::Version.for_designs(issue.designs).size).to eq(1)

            updated_designs = service.execute[:designs]

            expect(updated_designs.size).to eq(1)
            expect(updated_designs.first.versions.size).to eq(2)
          end

          context "when uploading a new design" do
            it "does not link the new version to the existing design" do
              existing_design = issue.designs.first

              updated_designs = described_class.new(project, user, issue: issue, files: [fixture_file_upload("spec/fixtures/dk.png")])
                                  .execute[:designs]

              expect(existing_design.versions.reload.size).to eq(1)
              expect(updated_designs.size).to eq(1)
              expect(updated_designs.first.versions.size).to eq(1)
            end
          end
        end

        context "when uploading multiple files" do
          let(:files) do
            [
              fixture_file_upload("spec/fixtures/rails_sample.jpg"),
              fixture_file_upload("spec/fixtures/dk.png")
            ]
          end

          it 'returns information about both designs in the response' do
            expect(service.execute).to include(designs: have_attributes(size: 2), status: :success)
          end

          it "creates 2 designs with a single version" do
            expect { service.execute }.to change { issue.designs.count }.from(0).to(2)
            expect(DesignManagement::Version.for_designs(issue.designs).size).to eq(1)
          end

          it "creates a single commit" do
            commit_count = -> do
              design_repository.expire_all_method_caches
              design_repository.commit_count
            end

            expect { service.execute }.to change { commit_count.call }.by(1)
          end

          it "only does 5 gitaly calls", :request_store do
            # Some unrelated calls that are usually cached or happen only once
            service.__send__(:repository).create_if_not_exists
            service.__send__(:repository).has_visible_content?

            # An exists?, a check for existing blobs, default branch, an after_commit
            # callback on LfsObjectsProject, and the creation of commits
            expect { service.execute }.to change { Gitlab::GitalyClient.get_request_count }.by(5)
          end

          context "when uploading too many files" do
            let(:files) { Array.new(DesignManagement::SaveDesignsService::MAX_FILES + 1) { fixture_file_upload("spec/fixtures/dk.png") } }

            it "returns the correct error" do
              expect(service.execute[:message]).to match(/only \d+ files are allowed simultaneously/i)
            end
          end
        end

        context "when the user is not allowed to upload designs" do
          let(:user) { create(:user) }

          it_behaves_like "a service error"
        end

        context "when creating the commit fails" do
          before do
            expect(service).to receive(:save_designs!).and_raise(Gitlab::Git::BaseError)
          end

          it_behaves_like "a service error"
        end

        context "when creating the versions fails" do
          before do
            expect(service).to receive(:save_designs!).and_raise(ActiveRecord::RecordInvalid)
          end

          it_behaves_like "a service error"
        end

        context "when a design already existed in the repo but we didn't know about it in the database" do
          before do
            path = File.join(build(:design, issue: issue, filename: "rails_sample.jpg").full_path)
            design_repository.create_if_not_exists
            design_repository.create_file(user, path, "something fake",
                                          branch_name: "master",
                                          message: "Somehow created without being tracked in db")
          end

          it "creates the design and a new version for it" do
            first_updated_design = service.execute[:designs].first

            expect(first_updated_design.filename).to eq("rails_sample.jpg")
            expect(first_updated_design.versions.size).to eq(1)
          end
        end
      end
    end
  end
end
