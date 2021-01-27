# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI Lint', :js do
  include Spec::Support::Helpers::Features::EditorLiteSpecHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit project_ci_lint_path(project)
  end

  describe 'YAML parsing' do
    shared_examples 'validates the YAML' do
      before do
        editor_set_value(yaml_content)

        click_on 'Validate'
      end

      context 'YAML is correct' do
        let(:yaml_content) do
          File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
        end

        it 'parses Yaml and displays the jobs' do
          expect(editor_get_value).to have_content(yaml_content)
          expect(page).to have_content('Status: Syntax is correct')

          within "table" do
            aggregate_failures do
              expect(page).to have_content('Job - rspec')
              expect(page).to have_content('Job - spinach')
              expect(page).to have_content('Deploy Job - staging')
              expect(page).to have_content('Deploy Job - production')
            end
          end
        end
      end

      context 'YAML is incorrect' do
        let(:yaml_content) { 'value: cannot have :' }

        it 'displays information about an error' do
          expect(editor_get_value).to have_content(yaml_content)
          expect(page).to have_content('Status: Syntax is incorrect')
        end
      end
    end

    it_behaves_like 'validates the YAML'

    context 'when Dry Run is checked' do
      before do
        check 'Simulate a pipeline created for the default branch'
      end

      it_behaves_like 'validates the YAML'
    end
  end

  describe 'YAML clearing' do
    context 'YAML is present' do
      let(:yaml_content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      end

      it 'YAML content is cleared' do
        click_on 'Clear'

        expect(editor_get_value).to have_content('')
      end
    end
  end
end
