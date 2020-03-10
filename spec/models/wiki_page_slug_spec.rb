# frozen_string_literal: true

require 'spec_helper'

describe WikiPageSlug do
  describe 'Associations' do
    it { is_expected.to belong_to(:wiki_page_meta) }
  end

  describe 'Validations' do
    let(:meta) do
      WikiPageMeta.create(project: create(:project),
                          canonical_slug: 'slippery',
                          title: 'looks like this')
    end

    subject { described_class.new(slug: 'slimey', wiki_page_meta: meta) }

    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:canonical) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:wiki_page_meta_id) }

    describe 'only_one_slug_can_be_canonical_per_meta_record' do
      context 'there are no other slugs' do
        it { is_expected.to be_valid }
      end

      context 'there are other slugs, but they are not canonical' do
        before do
          3.times do
            described_class.create(slug: FFaker::Lorem.characters(10), wiki_page_meta: meta)
          end
        end

        it { is_expected.to be_valid }
      end

      context 'there is already a canonical slug' do
        before do
          described_class.create(canonical: true, slug: FFaker::Lorem.characters(10), wiki_page_meta: meta)
        end

        it { is_expected.not_to be_valid }
      end
    end
  end
end
