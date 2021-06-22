# frozen_string_literal: true

RSpec.shared_examples 'ci_cd_settings delegation' do
  context 'when ci_cd_settings is destroyed but project is not' do
    it 'allows methods delegated to ci_cd_settings to be nil', :aggregate_failures do
      project = create(:project)
      attributes = project.ci_cd_settings.attributes.keys - %w(id project_id)
      project.ci_cd_settings.destroy
      project.reload
      attributes.each do |attr|
        method = project.respond_to?("ci_#{attr}") ? "ci_#{attr}" : attr
        expect(project.send(method)).to be_nil, "#{attr} was not nil"
      end
    end
  end
end
