# frozen_string_literal: true

RSpec.shared_examples 'an elasticsearch indexed container' do
  describe 'validations' do
    subject { create container }

    it 'validates uniqueness of main attribute' do
      is_expected.to validate_uniqueness_of(attribute)
    end
  end

  describe '.limited_ids_cached', :use_clean_rails_memory_store_caching do
    subject { create container }

    it 'returns correct values' do
      initial_ids = subject.class.limited_ids

      expect(initial_ids).not_to be_empty
      expect(subject.class.limited_ids_cached).to match_array(initial_ids)

      new_container = create container

      expect(subject.class.limited_ids_cached).to match_array(initial_ids + [new_container.id])

      new_container.destroy

      expect(subject.class.limited_ids_cached).to match_array(initial_ids)
    end
  end

  describe 'callbacks' do
    subject { build container }

    describe 'on save' do
      it 'triggers index_project' do
        is_expected.to receive(:index)

        subject.save!
      end

      it 'performs the expected action' do
        index_action

        subject.save!
      end

      it 'invalidates limited_ids cache' do
        is_expected.to receive(:drop_limited_ids_cache!)

        subject.save!
      end
    end

    describe 'on destroy' do
      subject { create container }

      it 'triggers delete_from_index' do
        is_expected.to receive(:delete_from_index)

        subject.destroy!
      end

      it 'performs the expected action' do
        delete_action

        subject.destroy!
      end

      it 'invalidates limited_ids cache' do
        is_expected.to receive(:drop_limited_ids_cache!)

        subject.destroy!
      end
    end
  end
end
