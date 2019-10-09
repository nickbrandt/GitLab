# frozen_string_literal: true

require 'spec_helper'

describe Security::VulnerabilitiesFinder do
  let(:project) { create(:project, :with_vulnerabilities) }

  subject { described_class.new(project).execute }

  it 'returns vulnerabilities of a project' do
    expect(subject).to match_array(project.vulnerabilities)
  end
end
