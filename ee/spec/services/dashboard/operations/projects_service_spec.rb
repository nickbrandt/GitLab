# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::Operations::ProjectsService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { described_class.new(user) }

  describe '#execute' do
    before do
      project.add_developer(user)
    end

    it 'returns the project when passing a project id' do
      projects = service.execute([project.id])

      expect(projects).to contain_exactly(project)
    end

    it 'returns the project when passing a project record' do
      projects = service.execute([project])

      expect(projects).to contain_exactly(project)
    end

    describe 'with plans' do
      let!(:gold_project) { create(:project, namespace: create(:namespace, plan: :gold_plan)) }
      let!(:silver_project) { create(:project, namespace: create(:namespace, plan: :silver_plan)) }
      let!(:no_plan_project) { create(:project, namespace: create(:namespace)) }

      let(:projects) { service.execute([gold_project, silver_project, no_plan_project]) }

      before do
        gold_project.add_developer(user)
        silver_project.add_developer(user)
        no_plan_project.add_developer(user)
      end

      context 'when namespace plan check is enabled' do
        before do
          stub_application_setting(check_namespace_plan: true)
        end

        it 'returns the gold project' do
          expect(projects).to contain_exactly(gold_project)
        end
      end

      context 'when namespace plan check is disabled' do
        before do
          stub_application_setting(check_namespace_plan: false)
        end

        it 'returns all projects' do
          expect(projects).to contain_exactly(gold_project, silver_project, no_plan_project)
        end
      end
    end

    context 'with insufficient access' do
      before do
        project.add_reporter(user)
      end

      it 'returns an empty list' do
        projects = service.execute([project.id])

        expect(projects).to be_empty
      end
    end

    it 'does not find by invalid project id' do
      projects = service.execute([-1])

      expect(projects).to be_empty
    end
  end
end
