# frozen_string_literal: true

require 'spec_helper'

describe SecretDetectionWorker do
  include Gitlab::Routing

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }
  let_it_be(:project_snippet) { create(:project_snippet, :repository, project: project, author: user) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :repository, author: user) }

  let(:identifier) { 'key-123' }
  let(:gl_repository) { "project-#{project.id}" }
  let(:branch_name) { 'feature' }
  let(:secret_token) { Gitlab::Shell.secret_token }
  let(:reference_counter) { double('ReferenceCounter') }
  let(:push_options) { ['ci.skip', 'another push option'] }
  let(:repository) { project.repository }
  let(:commit) { create(:commit) }
  let(:tree) { commit.tree }

  let(:changes) do
    "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{branch_name}"
  end

  let(:params) do
    {
      gl_repository: gl_repository,
      secret_token: secret_token,
      identifier: identifier,
      changes: changes,
      push_options: push_options
    }
  end

  subject {described_class.new.perform()}

  context 'AWS key' do
    context 'is present' do

    end

    context 'is not present' do

    end

  end

  context 'AWS secrets' do

  end
end