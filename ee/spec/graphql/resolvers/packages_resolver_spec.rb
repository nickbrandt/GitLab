# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:package, project: project) }

  describe '#resolve' do
    subject(:packages) { resolve(described_class, ctx: { current_user: user }, obj: project) }

    context 'when the package feature is enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'when the project has the package feature enabled' do
        before do
          allow(project).to receive(:feature_available?).with(:packages).and_return(true)
        end

        it { is_expected.to contain_exactly(package) }
      end

      context 'when the project has the package feature disabled' do
        before do
          allow(project).to receive(:feature_available?).with(:packages).and_return(false)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'when the package feature is not enabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it { is_expected.to be_nil }
    end
  end
end
