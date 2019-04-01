# frozen_string_literal: true

require "spec_helper"

describe ProjectWiki do
  let(:user) { create(:user, :commit_email) }
  let(:project) { create(:project, :wiki_repo, namespace: user.namespace) }
  let(:project_wiki) { described_class.new(project, user) }

  subject { project_wiki }

  describe "#kerberos_url_to_repo" do
    it 'returns valid kerberos url for this repo' do
      gitlab_kerberos_url = Gitlab.config.build_gitlab_kerberos_url
      repo_kerberos_url = "#{gitlab_kerberos_url}/#{subject.full_path}.git"

      expect(subject.kerberos_url_to_repo).to eq(repo_kerberos_url)
    end
  end
end
