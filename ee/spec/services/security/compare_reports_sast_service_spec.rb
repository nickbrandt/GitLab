# frozen_string_literal: true

require 'spec_helper'

describe Security::CompareReportsSastService, '#execute' do
  # Setup a project with 2 reports having 1 common vulnerability whose location is updated
  let(:project) { create(:project, :repository) }
  let(:branch_name) { 'master' }
  let(:identifier) { create(:ci_reports_security_identifier) }
  let(:location) { create(:ci_reports_security_locations_sast, file_path: 'a.js', start_line: 2, end_line: 4) }
  let(:location_updated) { create(:ci_reports_security_locations_sast, file_path: 'a.js', start_line: 3, end_line: 5) }
  let(:occurrence_1) { create(:ci_reports_security_occurrence, :dynamic, name: 'occurrence_1') }
  let(:occurrence_2) { create(:ci_reports_security_occurrence, name: 'occurrence_2', location: location, identifiers: [identifier]) }
  let(:occurrence_2_updated) { create(:ci_reports_security_occurrence, name: 'occurrence_2_updated', location: location_updated, identifiers: [identifier]) }
  let(:occurrence_3) { create(:ci_reports_security_occurrence, :dynamic, name: 'occurrence_3') }
  let(:base_report) { create(:ci_reports_security_report, commit_sha: base_sha, occurrences: [occurrence_1, occurrence_2]) }
  let(:head_report) { create(:ci_reports_security_report, commit_sha: head_sha, occurrences: [occurrence_2_updated, occurrence_3]) }

  let(:file_content) do
    <<-DIFF.strip_heredoc
      var auth = "Jane";
      if (userInput == auth) {
          console.log(userInput);
      }
    DIFF
  end

  let(:file_content_updated) do
    <<-DIFF.strip_heredoc
      var auth = "Jane";
      // Add a comment
      if (userInput == auth) {
          console.log(userInput);
      }
    DIFF
  end

  let(:base_sha) do
    create_file('a.js', file_content)
    project.commit(branch_name).id
  end

  subject { described_class.new(base_report, head_report, project).execute }

  shared_examples 'report diff with existing occurrence' do
    it 'returns added, existing and fixed occurrences' do
      expect(subject.added).to contain_exactly(occurrence_3)
      expect(subject.existing).to contain_exactly(occurrence_2)
      expect(subject.fixed).to contain_exactly(occurrence_1)
    end

    it 'returns existing occurrence with old location set' do
      expect(subject.existing.first.old_location).to eq(location)
    end
  end

  shared_examples 'report diff without existing occurrence' do
    it 'returns added and fixed occurrences but no existing ones' do
      expect(subject.added).to contain_exactly(occurrence_3, occurrence_2_updated)
      expect(subject.existing).to be_empty
      expect(subject.fixed).to contain_exactly(occurrence_1, occurrence_2)
    end
  end

  context 'when commit_sha are equal' do
    let(:head_sha) { base_sha }

    it_behaves_like 'report diff without existing occurrence'
  end

  context 'when there is no git diff available' do
    let(:head_sha) do
      update_file('a.js', file_content_updated)
      project.commit(branch_name).id
    end

    before do
      compare_service = spy
      allow(CompareService).to receive(:new).and_return(compare_service)
      allow(compare_service).to receive(:execute).and_return(nil)
    end

    it_behaves_like 'report diff without existing occurrence'
  end

  context 'when vulnerability line numbers are updated' do
    let(:head_sha) do
      update_file('a.js', file_content_updated)
      project.commit(branch_name).id
    end

    it_behaves_like 'report diff with existing occurrence'

    context 'without end_line' do
      let(:location) { create(:ci_reports_security_locations_sast, file_path: 'a.js', start_line: 2, end_line: nil) }
      let(:location_updated) { create(:ci_reports_security_locations_sast, file_path: 'a.js', start_line: 3, end_line: nil) }

      it_behaves_like 'report diff with existing occurrence'
    end

    context 'when line content is updated' do
      let(:file_content_updated) do
        <<-DIFF.strip_heredoc
          var auth = "Jane";
          // Add a comment
          if (input == auth) { // Add a comment here to change line content
              console.log(userInput);
          }
        DIFF
      end

      it_behaves_like 'report diff without existing occurrence'
    end
  end

  context 'when vulnerability file path is updated' do
    let(:location_updated) { create(:ci_reports_security_locations_sast, file_path: 'b.js', start_line: 2, end_line: 4) }

    let(:head_sha) do
      delete_file('a.js')
      create_file('b.js', file_content)
      project.commit(branch_name).id
    end

    it_behaves_like 'report diff with existing occurrence'
  end

  context 'when vulnerability file path and lines are updated' do
    let(:location_updated) { create(:ci_reports_security_locations_sast, file_path: 'b.js', start_line: 3, end_line: 5) }

    let(:head_sha) do
      delete_file('a.js')
      create_file('b.js', file_content_updated)
      project.commit(branch_name).id
    end

    it_behaves_like 'report diff with existing occurrence'
  end

  def create_file(file_name, content)
    Files::CreateService.new(
      project,
      project.owner,
      commit_message: 'Update',
      start_branch: branch_name,
      branch_name: branch_name,
      file_path: file_name,
      file_content: content
    ).execute
  end

  def update_file(file_name, content)
    Files::UpdateService.new(
      project,
      project.owner,
      commit_message: 'Update',
      start_branch: branch_name,
      branch_name: branch_name,
      file_path: file_name,
      file_content: content
    ).execute
  end

  def delete_file(file_name)
    Files::DeleteService.new(
      project,
      project.owner,
      commit_message: 'Update',
      start_branch: branch_name,
      branch_name: branch_name,
      file_path: file_name
    ).execute
  end
end
