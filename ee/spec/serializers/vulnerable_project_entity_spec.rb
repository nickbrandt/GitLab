# frozen_string_literal: true

require 'spec_helper'

describe VulnerableProjectEntity do
  SEVERITY_LEVELS = ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys

  let(:project) { create(:project) }
  let(:vulnerable_project) { ::Security::VulnerableProjectPresenter.new(project) }

  before do
    allow(::Vulnerabilities::Occurrence).to receive(:batch_count_by_project_and_severity).and_return(2)
  end

  subject { described_class.new(vulnerable_project) }

  SEVERITY_LEVELS.each do |severity_level|
    it "exposes a vulnerability count attribute for #{severity_level} vulnerabilities" do
      expect(subject.as_json["#{severity_level}_vulnerability_count".to_sym]).to be(2)
    end
  end
end
