# frozen_string_literal: true

require 'spec_helper'

describe Import::BitbucketServerProviderRepoEntity do
  let(:repo_data) do
    {
      "name" => "demo",
      "project" => {
        "name" => "demo"
      },
      "links" => {
        "self" => [
          {
            "href" => "http://local.bitbucket.server/demo/demo.git",
            "name" => "http"
          }
        ]
      }
    }
  end
  let(:repo) { BitbucketServer::Representation::Repo.new(repo_data) }

  subject { described_class.new(repo).as_json }

  it_behaves_like 'exposes required fields for import entity'
end
