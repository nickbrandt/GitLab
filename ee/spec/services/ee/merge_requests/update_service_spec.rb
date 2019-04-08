# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::UpdateService do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user, {}) }

  let(:merge_request) do
    create(:merge_request, :simple, title: 'Old title',
                                    source_project: project,
                                    author: user)
  end

  before do
    allow(service).to receive(:execute_hooks)
  end

  describe '#execute' do
    it_behaves_like 'existing issuable with scoped labels' do
      let(:issuable) { merge_request }
      let(:parent) { project }
    end
  end
end
