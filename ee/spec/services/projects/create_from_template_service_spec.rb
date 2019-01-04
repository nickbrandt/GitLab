require 'spec_helper'

describe Projects::CreateFromTemplateService do
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:user) { create(:user) }
  let(:project_name) { project.name }
  let(:use_custom_template) { true }

  let(:subgroup_1) { create(:group, parent: group) }
  let(:subgroup_1_1) { create(:group, parent: subgroup_1) }
  let(:project_template) { create(:project, :public, namespace: subgroup_1) }
  let(:namespace_id) { nil }
  let(:group_with_project_templates_id) { nil }

  let(:project_params) do
    {
      path: user.to_param,
      template_name: project_name,
      description: 'project description',
      visibility_level: Gitlab::VisibilityLevel::PUBLIC,
      use_custom_template: use_custom_template,
      namespace_id: namespace_id,
      group_with_project_templates_id: group_with_project_templates_id
    }
  end

  subject { described_class.new(user, project_params) }

  before do
    stub_licensed_features(custom_project_templates: true)
    stub_ee_application_setting(custom_project_templates_group_id: group.id)
  end

  context '#execute' do
    context 'does not create project from custom template' do
      after do
        project = subject.execute

        expect(project).to be_saved
        expect(project.repository.empty?).to be true
      end

      context 'when use_custom_template is not present or false' do
        let(:use_custom_template) { false }

        it 'creates an empty project' do
          expect(::Gitlab::ProjectTemplate).to receive(:find)
          expect(subject).not_to receive(:find_template_project)
        end
      end

      context 'when custom_project_templates feature is not enabled' do
        it 'creates an empty project' do
          stub_licensed_features(custom_project_templates: false)

          expect(::Gitlab::ProjectTemplate).to receive(:find)
          expect(subject).not_to receive(:find_template_project)
        end
      end

      context 'when custom_project_template does not exist' do
        let(:project_name) { 'whatever' }

        it 'creates an empty project' do
          expect(::Projects::GitlabProjectsImportService)
            .to receive(:new).with(user, hash_excluding(:custom_template), anything).and_call_original
        end
      end
    end

    shared_examples 'creates project from custom template' do |subgroup_id|
      # If we move the project inside a let block it throws a SEGFAULT error
      before do
        project_params[:group_with_project_templates_id] = subgroup_id
        @project = subject.execute
      end

      it 'returns the created project' do
        expect(@project).to be_saved
        expect(@project.import_scheduled?).to be(true)
      end

      context 'the result project' do
        it 'overrides template description' do
          expect(@project.description).to match('project description')
        end

        it 'overrides template visibility_level' do
          expect(@project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end
    end

    it_behaves_like 'creates project from custom template', nil
    it_behaves_like 'creates project from custom template', ''

    describe 'creating project from a Group project template', :postgresql do
      let(:project_name) { project_template.name }
      let(:group_with_project_templates_id) { subgroup_1.id }
      let(:group2) { create(:group) }

      before do
        group.add_maintainer(user)
        group2.add_maintainer(user)
      end

      context "when the namespace is out of the hierarchy of the Group's owning the template" do
        let(:namespace_id) { group2.id }

        it "isn't persisted" do
          project = subject.execute

          expect(project).not_to be_saved
          expect(project.repository.empty?).to eq(true)
        end
      end

      shared_examples 'a persisted project' do
        it "is persisted" do
          project = subject.execute

          expect(project).to be_saved
          expect(project.import_scheduled?).to be(true)
        end
      end

      context 'when project is created under a top level group' do
        let(:namespace_id) { group.id }

        it_behaves_like 'a persisted project'
      end

      context 'when project is created under a subgroup' do
        let(:namespace_id) { subgroup_1.id }

        it_behaves_like 'a persisted project'
      end

      context 'when project is created under a nested subgroup' do
        let(:namespace_id) { subgroup_1_1.id }

        it_behaves_like 'a persisted project'
      end
    end
  end
end
