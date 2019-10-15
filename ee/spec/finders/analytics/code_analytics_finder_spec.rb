# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CodeAnalyticsFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:gemfile) { create(:analytics_repository_file, project: project, file_path: 'Gemfile') }
    let_it_be(:user_model) { create(:analytics_repository_file, project: project, file_path: 'app/models/user.rb') }
    let_it_be(:app_controller) { create(:analytics_repository_file, project: project, file_path: 'app/controllers/application_controller.rb') }

    let_it_be(:date1) { Date.new(2018, 3, 5) }
    let_it_be(:date2) { Date.new(2018, 10, 20) }
    let_it_be(:date_outside_of_range) { Date.new(2019, 12, 1) }

    let_it_be(:gemfile_commit) { create(:analytics_repository_file_commit, project: project, analytics_repository_file: gemfile, committed_date: date1, commit_count: 2) }
    let_it_be(:gemfile_commit_other_day) { create(:analytics_repository_file_commit, project: project, analytics_repository_file: gemfile, committed_date: date2, commit_count: 1) }
    let_it_be(:user_model_commit) { create(:analytics_repository_file_commit, project: project, analytics_repository_file: user_model, committed_date: date1, commit_count: 5) }
    let_it_be(:controller_outside_of_range) { create(:analytics_repository_file_commit, project: project, analytics_repository_file: app_controller, committed_date: date_outside_of_range) }

    let(:params) { { project: project } }

    subject { described_class.new(params).execute }

    def find_file_count(result, file_path)
      result.find { |r| r.repository_file.file_path.eql?(file_path) }
    end

    context 'with no commits in the given date range' do
      before do
        params[:from] = 5.years.ago
        params[:to] = 4.years.ago
      end

      it 'returns empty array' do
        expect(subject).to eq([])
      end
    end

    context 'with commits in the given date range' do
      before do
        params[:from] = date1
        params[:to] = date2
      end

      it 'sums up the gemfile commits' do
        expect(find_file_count(subject, gemfile.file_path).count).to eq(3)
      end

      it 'includes the user model commit' do
        expect(find_file_count(subject, user_model.file_path).count).to eq(5)
      end

      it 'verifies that the out of range record is persisted' do
        expect(controller_outside_of_range).to be_persisted
        expect(controller_outside_of_range.committed_date).to eq(date_outside_of_range)
      end

      it 'does not include items outside of the date range' do
        expect(find_file_count(subject, app_controller.file_path)).to be_nil
      end

      it 'orders the results by commit count' do
        result_file_paths = subject.map { |item| item.repository_file.file_path }

        expect(result_file_paths).to eq([gemfile.file_path, user_model.file_path])
      end

      context 'when `file_count` is given' do
        before do
          params[:file_count] = 1
        end

        it 'limits the number of files' do
          expect(subject.size).to eq(1)
        end
      end
    end
  end
end
