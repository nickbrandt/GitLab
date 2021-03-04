# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::NamespaceProjectsResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }

  context "with a group" do
    let(:group) { create(:group) }
    let(:project_1) { create(:project, namespace: group) }
    let(:project_2) { create(:project, namespace: group) }

    before do
      project_1.add_developer(current_user)
      project_2.add_developer(current_user)

      project_1.project_setting.update!(has_vulnerabilities: true)
    end

    describe '#resolve' do
      context 'has_vulnerabilities' do
        subject(:projects) { resolve_projects(has_vulnerabilities: has_vulnerabilities) }

        context 'when the `has_vulnerabilities` parameter is not truthy' do
          let(:has_vulnerabilities) { false }

          it { is_expected.to contain_exactly(project_1, project_2) }
        end

        context 'when the `has_vulnerabilities` parameter is truthy' do
          let(:has_vulnerabilities) { true }

          it { is_expected.to contain_exactly(project_1) }
        end
      end

      context 'sorting' do
        let(:project_3) { create(:project, namespace: group) }

        before do
          project_1.statistics.update!(lfs_objects_size: 11, repository_size: 10)
          project_2.statistics.update!(lfs_objects_size: 10, repository_size: 12)
          project_3.statistics.update!(lfs_objects_size: 12, repository_size: 11)
        end

        context 'when sort equals :storage' do
          subject(:projects) { resolve_projects(sort: :storage) }

          it { is_expected.to eq([project_3, project_2, project_1]) }
        end

        context 'when sort does not equal :storage' do
          subject(:projects) { resolve_projects }

          it { is_expected.to eq([project_1, project_2, project_3]) }
        end
      end

      context 'has_code_coverage' do
        subject(:projects) { resolve_projects(has_code_coverage: has_code_coverage) }

        let!(:coverage_1) { create(:ci_daily_build_group_report_result, project: project_1) }

        context 'when has_code_coverage is false' do
          let(:has_code_coverage) { false }

          it { is_expected.to contain_exactly(project_1, project_2) }
        end

        context 'when has_code_coverage is true' do
          let(:has_code_coverage) { true }

          it { is_expected.to contain_exactly(project_1) }
        end
      end
    end
  end

  def resolve_projects(has_vulnerabilities: false, sort: :similarity, ids: nil, has_code_coverage: false)
    args = {
      include_subgroups: false,
      has_vulnerabilities: has_vulnerabilities,
      sort: sort,
      search: nil,
      ids: nil,
      has_code_coverage: has_code_coverage
    }

    resolve(described_class, obj: group, args: args, ctx: { current_user: current_user })
  end
end
