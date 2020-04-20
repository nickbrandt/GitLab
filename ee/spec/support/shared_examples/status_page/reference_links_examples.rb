# frozen_string_literal: true

# This shared_example requires the following variables:
# - object: The AR object
# - field: The entity field/AR attribute which contains the GFM reference
# - value: The resulting JSON value
RSpec.shared_examples 'reference links for status page' do
  let_it_be(:project, reload: true) { create(:project) }
  let(:gfm_reference) { reference.to_reference(full: true) }

  before do
    project.update!(visibility_level: project_visibility)
    object.update!(field => gfm_reference)

    expect(StatusPage::Renderer)
      .to receive(:markdown)
      .at_least(:once)
      .and_call_original
  end

  shared_examples 'html reference' do
    it 'shows link anchor with HTML data attributes' do
      aggregate_failures do
        expect(value).to include(gfm_reference)
        expect(value).to include('<a ')
        expect(value).to include(%{title="#{reference.title}"})
      end
    end
  end

  shared_examples 'plain reference' do
    it 'redacts link anchor and HTML data attributes' do
      aggregate_failures do
        expect(value).to include(gfm_reference)
        expect(value).not_to include('<a ')
        expect(value).not_to include(%{title="#{reference.title}"})
      end
    end
  end

  context 'with public project' do
    let(:project_visibility) { Project::PUBLIC }

    context 'with public issue' do
      let(:reference) { create(:issue, project: project) }

      include_examples 'html reference'
    end

    context 'with confidential issue' do
      let(:reference) { create(:issue, :confidential, project: project) }

      include_examples 'plain reference'
    end
  end

  context 'with private project' do
    let(:project_visibility) { Project::PRIVATE }

    context 'with public issue' do
      let(:reference) { create(:issue, project: project) }

      include_examples 'plain reference'
    end
  end
end
