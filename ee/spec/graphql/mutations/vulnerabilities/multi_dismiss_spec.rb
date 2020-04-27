# frozen_string_literal: true
require 'spec_helper'

describe Mutations::Vulnerabilities::MultiDismiss do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:vulnerabilities) { create_list(:vulnerability, 5, :with_findings) }
    let_it_be(:user) { create(:user) }

    let(:comment) { 'Dismissal Feedback' }
    let(:mutated_vulnerabilities) { subject[:vulnerabilities] }

    subject { mutation.resolve(vulnerability_ids: vulnerabilities.map(&GitlabSchema.method(:id_from_object)), comment: comment) }

    context 'when the user can dismiss vulnerabilities' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user doe not have access to the project of at least one vulnerability' do
        before do
          vulnerabilities.first.project.add_developer(user)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has access to the project' do
        before do
          vulnerabilities.each { |vulnerability| vulnerability.project.add_developer(user) }
        end

        it 'returns the dismissed vulnerability' do
          expect(mutated_vulnerabilities).to match_array(vulnerabilities)
          expect(mutated_vulnerabilities).to all(be_dismissed)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
