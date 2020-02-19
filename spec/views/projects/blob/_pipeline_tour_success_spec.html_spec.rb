# frozen_string_literal: true

require 'spec_helper'

describe 'projects/blob/_pipeline_tour_success' do
  let(:project) { create(:project) }

  before do
    assign(:project, project)
    allow(view).to receive(:suggest_pipeline_commit_cookie_name).and_return('some_cookie')
  end

  it 'has basic structure and content' do
    render

    expect(rendered).to have_selector('h4', text: "That's it, well done!")
    expect(rendered).to have_selector('button.close')
    expect(rendered).to have_selector('p', text: 'The pipeline will now run automatically every time you commit code.')
    expect(rendered).to have_link("Beginner's Guide to Continuous Integration", href: 'https://about.gitlab.com/blog/2018/01/22/a-beginners-guide-to-continuous-integration/')
    expect(rendered).to have_link('examples of GitLab CI/CD', href: 'https://docs.gitlab.com/ee/ci/examples/')
    expect(rendered).to have_link('Go to Pipelines', href: "/#{project.full_path}/pipelines", class: 'btn-success')
  end
end
