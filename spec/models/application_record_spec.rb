# frozen_string_literal: true

require 'spec_helper'

describe ApplicationRecord do
  describe '#id_in' do
    let(:records) { create_list(:user, 3) }

    it 'returns records of the ids' do
      expect(User.id_in(records.last(2).map(&:id))).to eq(records.last(2))
    end
  end

  describe '.safe_ensure_unique' do
    let(:model) { build(:suggestion) }
    let(:klass) { model.class }

    before do
      allow(model).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
    end

    it 'returns false when ActiveRecord::RecordNotUnique is raised' do
      expect(model).to receive(:save).once
      expect(klass.safe_ensure_unique { model.save }).to be_falsey
    end

    it 'retries based on retry count specified' do
      expect(model).to receive(:save).exactly(3).times
      expect(klass.safe_ensure_unique(retries: 2) { model.save }).to be_falsey
    end
  end

  describe '.safe_find_or_create_by' do
    it 'creates the user avoiding race conditions' do
      expect(Suggestion).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordNotUnique)
      allow(Suggestion).to receive(:find_or_create_by).and_call_original

      expect { Suggestion.safe_find_or_create_by(build(:suggestion).attributes) }
        .to change { Suggestion.count }.by(1)
    end
  end

  describe '.safe_find_or_create_by!' do
    it 'creates a record using safe_find_or_create_by' do
      expect(Suggestion).to receive(:find_or_create_by).and_call_original

      expect(Suggestion.safe_find_or_create_by!(build(:suggestion).attributes))
        .to be_a(Suggestion)
    end

    it 'raises a validation error if the record was not persisted' do
      expect { Suggestion.find_or_create_by!(note: nil) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '.underscore' do
    it 'returns the underscored value of the class as a string' do
      expect(MergeRequest.underscore).to eq('merge_request')
    end
  end

  describe '.try_bulk_insert_on_save' do
    let(:items) { [1, 2, 3] }

    class WithBulkInsertSupport < ApplicationRecord
      include ::BulkInsertableAssociations
    end

    describe WithBulkInsertSupport do
      context 'when the given association is bulk-insert safe' do
        it 'queues up items for bulk-insertion and returns true' do
          expect(described_class).to receive(:supports_bulk_insert?).and_return true
          expect(described_class).to receive(:bulk_insert_on_save).with(:association, items).and_return(items)

          expect(described_class.try_bulk_insert_on_save(:association, items)).to be_truthy
        end
      end

      context 'when the given association is not bulk-insert safe' do
        it 'does not queue up items for bulk-insertion and returns false' do
          expect(described_class).to receive(:supports_bulk_insert?).and_return false
          expect(described_class).not_to receive(:bulk_insert_on_save)

          expect(described_class.try_bulk_insert_on_save(:association, items)).to be_falsey
        end
      end
    end

    class WithoutBulkInsertSupport < ApplicationRecord
      has_many :projects
      has_many :label_links
    end

    describe WithoutBulkInsertSupport do
      it 'does not queue up items for bulk-insertion and returns false' do
        expect(described_class).not_to receive(:bulk_insert_on_save)

        expect(described_class.try_bulk_insert_on_save(:label_links, items)).to be_falsey
      end
    end
  end
end
