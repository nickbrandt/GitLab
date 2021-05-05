# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::RepositoryBranchNamesResolver do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }

  describe '#resolve' do
    subject(:resolve_branch_names) do
      resolve(
        described_class,
        obj: project.repository,
        args: { search_pattern: pattern, offset: offset, limit: 1 },
        ctx: { current_user: project.creator }
      )
    end

    context 'with zero offset' do
      let(:offset) { 0 }

      context 'with empty search pattern' do
        let(:pattern) { '' }

        it 'returns nil' do
          expect(resolve_branch_names).to eq(nil)
        end
      end

      context 'with a valid search pattern' do
        let(:pattern) { 'snippet/*' }

        it 'returns matching branches' do
          expect(resolve_branch_names).to contain_exactly('snippet/rename-and-edit-file')
        end
      end
    end

    context 'with offset' do
      let(:pattern) { 'snippet/*' }
      let(:offset) { 1 }

      it 'skips first match' do
        expect(resolve_branch_names).to contain_exactly('snippet/edit-file')
      end
    end
  end
end
