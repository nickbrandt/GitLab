# frozen_string_literal: true

require 'spec_helper'

describe WikiPage::Slug do
  let_it_be(:project) { create(:project) }
  let_it_be(:meta) do
    WikiPage::Meta.create(project: project, title: 'looks like this')
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:wiki_page_meta) }

    it 'refers correctly to the wiki_page_meta' do
      created = described_class.create(slug: any_slug, wiki_page_meta: meta)

      expect(created.reload.wiki_page_meta).to eq(meta)
    end
  end

  describe 'scopes' do
    describe 'canonical' do
      subject { described_class.canonical }

      context 'there are no slugs' do
        it { is_expected.to be_empty }
      end

      context 'there are some non-canonical slugs' do
        before do
          3.times do
            described_class.create(slug: any_slug, wiki_page_meta: meta)
          end
        end

        it { is_expected.to be_empty }
      end

      context 'there is at least one canonical slugs' do
        before do
          described_class.create(canonical: true, slug: any_slug, wiki_page_meta: meta)
        end

        it { is_expected.not_to be_empty }
      end
    end
  end

  describe 'Validations' do
    let(:canonical) { false }

    subject do
      described_class.new(canonical: canonical, slug: 'slimey', wiki_page_meta: meta)
    end

    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:wiki_page_meta_id) }

    describe 'only_one_slug_can_be_canonical_per_meta_record' do
      context 'there are no other slugs' do
        it { is_expected.to be_valid }

        context 'the current slug is canonical' do
          let(:canonical) { true }

          it { is_expected.to be_valid }
        end
      end

      context 'there are other slugs, but they are not canonical' do
        before do
          3.times do
            described_class.create(slug: any_slug, wiki_page_meta: meta)
          end
        end

        it { is_expected.to be_valid }

        context 'the current slug is canonical' do
          let(:canonical) { true }

          it { is_expected.to be_valid }
        end
      end

      context 'there is already a canonical slug' do
        before do
          described_class.create(canonical: true, slug: any_slug, wiki_page_meta: meta)
        end

        it { is_expected.to be_valid }

        context 'the current slug is canonical' do
          let(:canonical) { true }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  def any_slug
    FFaker::Lorem.characters(10)
  end
end
