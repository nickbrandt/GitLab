# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::AdditionalPacks::ChangeNamespaceService do
  describe '#execute' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:target) { create(:group) }
    let_it_be(:subgroup) { build(:group, :nested) }
    let_it_be(:existing_packs) { create_list(:ci_minutes_additional_pack, 5, namespace: namespace) }
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:non_admin) { build(:user) }

    subject(:change_namespace) { described_class.new(user, namespace, target).execute }

    context 'with a non-admin user' do
      let(:user) { non_admin }

      it 'raises an error' do
        expect { change_namespace }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'with an admin user' do
      let(:user) { admin }

      context 'with valid namespace and target namespace' do
        before do
          namespace.add_owner(admin)
          target.add_owner(admin)
        end

        it 'moves all existing packs to the target namespace', :aggregate_failures do
          expect(target.ci_minutes_additional_packs).to be_empty

          change_namespace

          expect(target.ci_minutes_additional_packs).to match_array(existing_packs)
          expect(existing_packs.first.reload.namespace).to eq target
          expect(change_namespace[:status]).to eq :success
        end

        context 'when updating packs fails' do
          before do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:success).and_raise(StandardError)
            end
          end

          it 'rolls back updates for all packs', :aggregate_failures do
            expect { change_namespace }.to raise_error(StandardError)
            expect(namespace.ci_minutes_additional_packs.count).to eq 5
            expect(target.ci_minutes_additional_packs.count).to eq 0
          end
        end

        context 'when the namespace has no additional packs to move' do
          before do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:additional_packs).and_return([])
            end
          end

          it 'returns success' do
            expect(change_namespace[:status]).to eq :success
          end
        end
      end

      context 'when the namespace is not provided' do
        let(:namespace) { nil }

        it 'returns an error' do
          expect(change_namespace[:status]).to eq :error
          expect(change_namespace[:message]).to eq 'Namespace must be provided'
        end
      end

      context 'when the target namespace is not provided' do
        let(:target) { nil }

        it 'returns an error' do
          expect(change_namespace[:status]).to eq :error
          expect(change_namespace[:message]).to eq 'Target namespace must be provided'
        end
      end

      context 'when the namespace is not a top-level namespace' do
        let(:namespace) { subgroup }

        it 'returns an error' do
          expect(change_namespace[:status]).to eq :error
          expect(change_namespace[:message]).to eq 'Namespace must be a top-level namespace'
        end
      end

      context 'when the target namespace is not a top-level namespace' do
        let(:target) { subgroup }

        it 'returns an error' do
          expect(change_namespace[:status]).to eq :error
          expect(change_namespace[:message]).to eq 'Target namespace must be a top-level namespace'
        end
      end

      context 'when the namespaces do not share an owner' do
        let(:namespace) { create(:group) }

        it 'returns an error' do
          expect(change_namespace[:status]).to eq :error
          expect(change_namespace[:message]).to eq 'Both namespaces must share the same owner'
        end
      end
    end
  end
end
