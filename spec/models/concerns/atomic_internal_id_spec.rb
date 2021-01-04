# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AtomicInternalId do
  let(:milestone) { build(:milestone) }
  let(:iid) { double('iid', to_i: 42) }
  let(:external_iid) { 100 }
  let(:scope_attrs) { { project: milestone.project } }
  let(:usage) { :milestones }

  describe '#save!' do
    context 'when IID is provided' do
      before do
        milestone.iid = external_iid
      end

      it 'tracks the value' do
        expect(milestone).to receive(:track_project_iid!)

        milestone.save!
      end

      context 'when importing' do
        before do
          milestone.importing = true
        end

        it 'does not track the value' do
          expect(milestone).not_to receive(:track_project_iid!)

          milestone.save!
        end
      end

      context 'when the save is rolled back' do
        context 'when no ensure_if condition is given' do
          it 'clears the instance IID' do
            expect(milestone).to receive(:clear_project_iid!).and_call_original

            ActiveRecord::Base.transaction(requires_new: true) do
              milestone.save!

              expect(milestone.iid).to eq(external_iid)

              raise ActiveRecord::Rollback
            end

            expect(milestone.iid).to be_nil
          end
        end

        context 'when an ensure_if condition is given' do
          let(:test_class) do
            Class.new(ApplicationRecord) do
              include AtomicInternalId
              include Importable

              self.table_name = :milestones

              belongs_to :project

              has_internal_id :iid, scope: :project, track_if: -> { !importing }, ensure_if: -> { !importing }

              def self.name
                'TestClass'
              end
            end
          end

          let(:instance) { test_class.new(milestone.attributes) }

          context 'when the ensure_if condition evaluates to false' do
            it 'clears the instance IID' do
              expect(instance).to receive(:clear_project_iid!).and_call_original

              ActiveRecord::Base.transaction(requires_new: true) do
                instance.save!

                expect(instance.iid).not_to be_nil

                raise ActiveRecord::Rollback
              end

              expect(instance.iid).to be_nil
            end
          end

          context 'when the ensure_if condition evaluates to true' do
            before do
              instance.importing = true
            end

            it 'does not clear the instance IID' do
              expect(instance).not_to receive(:clear_project_iid!)

              ActiveRecord::Base.transaction(requires_new: true) do
                instance.save!

                expect(instance.iid).not_to be_nil

                raise ActiveRecord::Rollback
              end

              expect(instance.iid).not_to be_nil
            end
          end
        end
      end
    end
  end

  describe '#track_project_iid!' do
    subject { milestone.track_project_iid! }

    it 'tracks the present value' do
      milestone.iid = external_iid

      expect(InternalId).to receive(:track_greatest).once.with(milestone, scope_attrs, usage, external_iid, anything)
      expect(InternalId).not_to receive(:generate_next)

      subject
    end

    context 'when value is set by ensure_project_iid!' do
      it 'does not track the value' do
        expect(InternalId).not_to receive(:track_greatest)

        milestone.ensure_project_iid!
        subject
      end

      it 'tracks the iid for the scope that is actually present' do
        milestone.iid = external_iid

        expect(InternalId).to receive(:track_greatest).once.with(milestone, scope_attrs, usage, external_iid, anything)
        expect(InternalId).not_to receive(:generate_next)

        # group scope is not present here, the milestone does not have a group
        milestone.track_group_iid!
        subject
      end
    end
  end

  describe '#ensure_project_iid!' do
    subject { milestone.ensure_project_iid! }

    it 'generates a new value if non is present' do
      expect(InternalId).to receive(:generate_next).with(milestone, scope_attrs, usage, anything).and_return(iid)

      expect { subject }.to change { milestone.iid }.from(nil).to(iid.to_i)
    end

    it 'generates a new value if first set with iid= but later set to nil' do
      expect(InternalId).to receive(:generate_next).with(milestone, scope_attrs, usage, anything).and_return(iid)

      milestone.iid = external_iid
      milestone.iid = nil

      expect { subject }.to change { milestone.iid }.from(nil).to(iid.to_i)
    end
  end

  describe '.with_project_iid_supply' do
    let(:iid) { 100 }

    it 'wraps generate and track_greatest in a concurrency-safe lock' do
      expect_next_instance_of(InternalId::InternalIdGenerator) do |g|
        expect(g).to receive(:with_lock).and_call_original
        expect(g.record).to receive(:last_value).and_return(iid)
        expect(g).to receive(:track_greatest).with(iid + 4)
      end

      ::Milestone.with_project_iid_supply(milestone.project) do |supply|
        4.times { supply.next_value }
      end
    end
  end
end
