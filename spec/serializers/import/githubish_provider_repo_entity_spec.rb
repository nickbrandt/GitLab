# frozen_string_literal: true

require 'spec_helper'

describe Import::GithubishProviderRepoEntity do
  let(:repo) do
    {
      id: 1,
      full_name: 'full/name',
      name: 'name',
      owner: { login: 'owner' }
    }
  end

  subject { described_class.new(repo).as_json }

  it_behaves_like 'exposes required fields for import entity'
end
