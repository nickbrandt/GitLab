# frozen_string_literal: true

require 'spec_helper'

describe WebIdeTerminal do
  let(:build) { create(:ci_build) }

  subject { described_class.new(build) }

  it 'returns the show_path of the build' do
    expect(subject.show_path).to end_with("/ide_terminals/#{build.id}")
  end

  it 'returns the retry_path of the build' do
    expect(subject.retry_path).to end_with("/ide_terminals/#{build.id}/retry")
  end

  it 'returns the cancel_path of the build' do
    expect(subject.cancel_path).to end_with("/ide_terminals/#{build.id}/cancel")
  end

  it 'returns the terminal_path of the build' do
    expect(subject.terminal_path).to end_with("/jobs/#{build.id}/terminal.ws")
  end
end
