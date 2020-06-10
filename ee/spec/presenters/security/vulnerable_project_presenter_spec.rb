# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::VulnerableProjectPresenter do
  let(:project) { create(:project) }

  before do
    allow(::Vulnerabilities::Occurrence).to receive(:batch_count_by_project_and_severity).and_return(1)
  end

  subject { described_class.new(project) }

  it 'presents the given project' do
    expect(subject.id).to be(project.id)
  end

  ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.each do |severity_level|
    it "exposes a vulnerability count attribute for #{severity_level} vulnerabilities" do
      expect(subject.public_send("#{severity_level}_vulnerability_count")).to be(1)
    end
  end
end
