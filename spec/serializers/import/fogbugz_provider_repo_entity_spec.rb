# frozen_string_literal: true

require 'spec_helper'

describe Import::FogbugzProviderRepoEntity do
  let(:repo_data) do
    {
      "ixProject" => "foo",
      "sProject" => "demo"
    }
  end
  let(:repo) { Gitlab::FogbugzImport::Repository.new(repo_data) }

  subject { described_class.new(repo).as_json }

  it_behaves_like 'exposes required fields for import entity'
end
