# frozen_string_literal: true

require 'spec_helper'

describe EE::Audit::ProjectFeatureChangesAuditor do
  describe '#execute' do
    let!(:user) { create(:user) }
    let!(:project) { create(:project, :pages_enabled, visibility_level: 0) }
    let(:features) { project.project_feature }
    let(:foo_instance) { described_class.new(user, features, project) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    it 'creates an event when any project feature level changes' do
      columns = project.project_feature.attributes.keys.select { |attr| attr.end_with?('level') }

      columns.each do |column|
        features.update_attribute(column, 0)
        expect { foo_instance.execute }.to change { SecurityEvent.count }.by(1)

        event = SecurityEvent.last
        expect(event.details[:from]).to eq 'Public'
        expect(event.details[:to]).to eq 'Private'
        expect(event.details[:change]).to eq column
      end
    end
  end
end
