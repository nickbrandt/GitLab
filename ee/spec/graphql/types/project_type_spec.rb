# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Project'] do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:vulnerability) { create(:vulnerability, project: project, severity: :high) }

  before do
    project.add_developer(user)
  end

  it 'includes the ee specific fields' do
    expected_fields = %w[
      service_desk_enabled service_desk_address vulnerabilities
      requirement_states_count vulnerability_severities_count
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'vulnerabilities' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:vulnerability) do
      create(:vulnerability, :detected, :critical, project: project, title: 'A terrible one!')
    end

    let_it_be(:query) do
      %(
        query {
          project(fullPath:"#{project.full_path}") {
            vulnerabilities {
              nodes {
                title
                severity
                state
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when first_class_vulnerabilities is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'is null' do
        vulnerabilities = subject.dig('data', 'project', 'vulnerabilities')

        expect(vulnerabilities).to be_nil
      end
    end

    context 'when first_class_vulnerabilities is enabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: true)
        stub_licensed_features(security_dashboard: true)
      end

      it "returns the project's vulnerabilities" do
        vulnerabilities = subject.dig('data', 'project', 'vulnerabilities', 'nodes')

        expect(vulnerabilities.count).to be(1)
        expect(vulnerabilities.first['title']).to eq('A terrible one!')
        expect(vulnerabilities.first['state']).to eq('DETECTED')
        expect(vulnerabilities.first['severity']).to eq('CRITICAL')
      end
    end
  end
end
