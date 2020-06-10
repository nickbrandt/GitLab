# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VulnerableProjectSerializer do
  let(:project) { create(:project) }
  let(:serializer) { described_class.new(project: project, current_user: user) }
  let(:user) { create(:user) }
  let(:vulnerable_project) { ::Security::VulnerableProjectPresenter.new(project) }

  before do
    project.add_developer(user)

    allow(::Vulnerabilities::Occurrence).to receive(:batch_count_by_project_and_severity)
  end

  describe '#represent' do
    subject { serializer.represent(vulnerable_project) }

    it 'includes counts for each severity of vulnerability' do
      ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.each do |severity_level|
        expect(subject).to include("#{severity_level}_vulnerability_count".to_sym)
      end
    end
  end
end
