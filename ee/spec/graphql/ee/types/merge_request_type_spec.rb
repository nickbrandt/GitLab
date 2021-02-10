# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequest'] do
  it { expect(described_class).to have_graphql_fields(:approvals_required, :merge_trains_count).at_least }
  it { expect(described_class).to have_graphql_field(:approved, complexity: 2, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:approvals_left, complexity: 2, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:has_security_reports, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:security_reports_up_to_date_on_target_branch, calls_gitaly?: true) }

  describe '#security_reports_up_to_date_on_target_branch' do
    subject(:execute_query) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let!(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let(:project) { create(:project, :public) }
    let(:current_user) { create :admin }
    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            mergeRequests {
              nodes {
                securityReportsUpToDateOnTargetBranch
              }
            }
          }
        }
      )
    end

    it 'delegates the security_reports_up_to_date? call to the merge request entity' do
      expect_next_found_instance_of(MergeRequest) do |instance|
        expect(instance).to receive(:security_reports_up_to_date?)
      end

      execute_query
    end
  end
end
