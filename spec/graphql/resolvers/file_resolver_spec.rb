# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::FileResolver do
  include GraphqlHelpers

  subject(:file) { resolve(described_class, args: { full_path: full_path, file_path: file_path, ref: ref }) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:file_path) { 'README.md' }
  let(:ref) { 'master' }

  before do
    project.add_developer(current_user)
  end

  it 'returns content of the file' do
    expect(file).to include(:content)
  end
end
