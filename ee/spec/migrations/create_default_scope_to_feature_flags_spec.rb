# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20190111183834_create_default_scope_to_feature_flags.rb')

describe CreateDefaultScopeToFeatureFlags, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create(name: 'test', path: 'test') }
  let(:projects) { table(:projects) }
  let(:project) { projects.create(name: 'test', namespace_id: namespace.id) }
  let(:feature_flags) { table(:operations_feature_flags) }
  let(:feature_flag_scopes) { table(:operations_feature_flag_scopes) }

  let!(:feature_flag_1) do
    feature_flags.create!(
      project_id: project.id,
      name: 'ci_live_trace',
      active: true,
      description: 'For live trace',
      created_at: "'2017-10-17 20:24:02'",
      updated_at: "'2017-10-17 20:24:02'"
    )
  end

  let!(:feature_flag_2) do
    feature_flags.create!(
      project_id: project.id,
      name: 'ci_merge_request',
      active: false,
      description: 'For merge request',
      created_at: "'2017-10-17 20:24:02'",
      updated_at: "'2017-10-17 20:24:02'"
    )
  end

  describe '#up' do
    subject { described_class.new.up }

    let(:scope_1) do
      feature_flag_scopes.find_by_feature_flag_id(feature_flag_1.id)
    end

    let(:scope_2) do
      feature_flag_scopes.find_by_feature_flag_id(feature_flag_2.id)
    end

    it 'creates default scopes for existing rows' do
      subject

      expect(scope_1).to be_active
      expect(scope_1.environment_scope).to eq('*')
      expect(scope_2).not_to be_active
      expect(scope_2.environment_scope).to eq('*')
    end

    context 'when a feature flag has already had default scope' do
      let!(:feature_flag_scope_1) do
        feature_flag_scopes.create!(
          feature_flag_id: feature_flag_1.id,
          environment_scope: '*',
          active: true,
          created_at: "'2017-10-17 20:24:02'",
          updated_at: "'2017-10-17 20:24:02'"
        )
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end

      it 'creates default scopes for a feature flag' do
        subject

        expect(scope_2).not_to be_active
        expect(scope_2.environment_scope).to eq('*')
      end
    end

    context 'when there are no feature flags' do
      let!(:feature_flag_1) { }
      let!(:feature_flag_2) { }

      it 'does not create scopes' do
        expect { subject }.not_to change { feature_flag_scopes.count }
      end
    end
  end

  describe '#down' do
    subject { described_class.new.down }

    let!(:feature_flag_scope_1) do
      feature_flag_scopes.create!(
        feature_flag_id: feature_flag_1.id,
        environment_scope: '*',
        active: true,
        created_at: "'2017-10-17 20:24:02'",
        updated_at: "'2017-10-17 20:24:02'"
      )
    end

    it 'deletes default scopes' do
      expect { subject }.to change { feature_flag_scopes.count }.by(-1)
    end

    it 'does not affect feature flags' do
      expect { subject }.not_to change { feature_flags.count }
    end
  end
end
