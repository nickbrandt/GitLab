# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSettings::UpdateService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:settings) { {} }

  subject(:service) { described_class.new(user, group, settings) }

  describe "#execute" do
    context "group has no namespace_settings" do
      before do
        group.namespace_settings.destroy!
      end

      it "builds out a new namespace_settings record" do
        expect do
          service.execute
        end.to change { NamespaceSetting.count }.by(1)
      end
    end

    context "group has a namespace_settings" do
      before do
        service.execute
      end

      it "doesn't create a new namespace_setting record" do
        expect do
          service.execute
        end.not_to change { NamespaceSetting.count }
      end
    end

    context "updating :default_branch_name" do
      let(:example_branch_name) { "example_branch_name" }
      let(:settings) { { default_branch_name: example_branch_name } }

      it "changes settings" do
        expect { service.execute }
          .to change { group.namespace_settings.default_branch_name }
          .from(nil).to(example_branch_name)
      end
    end

    context "updating :resource_access_tokens_enabled" do
      let(:settings) { { resource_access_tokens_enabled: false } }

      context 'with admin user' do
        let(:user) { create(:user, :admin) }

        it 'updates the setting' do
          expect { service.execute }
            .to change { group.namespace_settings.resource_access_tokens_enabled }
            .from(true).to(false)
        end
      end

      context 'with a non-admin user' do
        it 'does not update the setting' do
          expect { service.execute }.not_to change { group.namespace_settings.resource_access_tokens_enabled }
          expect(group.errors.messages[:resource_access_tokens_enabled]).to include("can only be changed by a group admin.")
        end
      end
    end
  end
end
