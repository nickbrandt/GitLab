# frozen_string_literal: true

require 'spec_helper'

describe Security::VulnerabilitiesFinder do
  let(:project) { create(:project, :with_vulnerabilities) }
  let(:params) { { page: 2, per_page: 1 } }

  subject { described_class.new(project, params).execute }

  it 'returns vulnerabilities of a project and respects pagination params' do
    expect(subject).to contain_exactly(project.vulnerabilities.drop(1).take(1).first)
  end
end
