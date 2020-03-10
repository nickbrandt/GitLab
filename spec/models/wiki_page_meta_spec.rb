# frozen_string_literal: true

require 'spec_helper'

describe WikiPageMeta do
  let_it_be(:project) { create(:project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:slugs) }
    it { is_expected.to have_many(:events) }
  end

  describe 'Validations' do
    subject do
      described_class.new(title: 'some title', project: project)
    end

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe '.find_or_create' do
    let(:title) { FFaker::Lorem.sentence }
    let(:old_title) { FFaker::Lorem.sentence }
    let(:last_known_slug) { FFaker::Lorem.characters(10) }
    let(:current_slug) { wiki_page.slug }
    let(:wiki_page) { create(:wiki_page, title: title, project: project) }

    def find_record
      described_class.find_or_create(last_known_slug, wiki_page)
    end

    def create_previous_version
      meta = described_class.create!(
        canonical_slug: last_known_slug,
        title: old_title,
        project: project
      )
      meta.slugs.find_or_create_by(slug: last_known_slug)
    end

    shared_examples 'metadata examples' do
      it 'establishes the correct state', :aggregate_failures do
        meta = find_record

        expect(meta.canonical_slug).to eq(wiki_page.slug)
        expect(meta.title).to eq(wiki_page.title)
        expect(meta.project).to eq(wiki_page.wiki.project)
        expect(meta.slugs.where(slug: last_known_slug)).to exist
        expect(meta.slugs.where(slug: wiki_page.slug)).to exist
      end

      it 'makes a reasonable number of DB queries' do
        expect(project).to eq(wiki_page.wiki.project)

        expect { find_record }.not_to exceed_query_limit(query_limit)
      end
    end

    context 'the slug is too long' do
      let(:last_known_slug) { FFaker::Lorem.characters(2050) }

      it 'raises an error' do
        expect { find_record }.to raise_error ActiveRecord::ValueTooLong
      end
    end

    context 'no existing record exists' do
      include_examples 'metadata examples' do
        # The base case is 10 queries:
        #  - 9 to set up the WikiPageMeta object. Of these:
        #    - 4 for savepoints (start and release)
        #    - 2 for uniqueness validation checks
        #    - 1 for fetch before create
        #    - 1 for create
        #    - 1 for canonical_slug update
        #  - 1 to insert slugs
        #
        # (Log has been edited for clarity)
        # 1. SELECT * FROM wiki_page_meta WHERE canonical_slug = ? AND project_id = ? LIMIT 1
        # 2. SAVEPOINT active_record_2 /*application:test,correlation_id:54d4bb6f39422ed5a56096febb1cca03*/
        # 3.  SELECT 1 AS one FROM wiki_page_meta WHERE canonical_slug = ? AND project_id = ?
        # 4.  INSERT INTO wiki_page_meta (project_id, title, canonical_slug) VALUES (?, ?, ?) returning id
        # 5. RELEASE SAVEPOINT active_record_2
        # 6. SAVEPOINT active_record_2
        # 7   SELECT 1 AS one FROM wiki_page_meta WHERE canonical_slug = ? AND id != ? AND project_id = ?
        # 8.  UPDATE wiki_page_meta SET canonical_slug = ? WHERE id = ?
        # 9. RELEASE SAVEPOINT active_record_2
        # 10.INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug) VALUES (?, ?) (?, ?)
        #        ON CONFLICT DO NOTHING RETURNING id
        let(:query_limit) { 10 }
      end
    end

    context 'the last_known_slug is the same as the current slug, as on creation' do
      let(:last_known_slug) { current_slug }

      include_examples 'metadata examples' do
        # Same as the base case, without 6-9, which are no longer necessary
        let(:query_limit) { 6 }
      end
    end

    context 'a record exists in the DB in the correct state' do
      let(:last_known_slug) { current_slug }
      let(:old_title) { title }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as the base case, without 2-5 and 6-9, which are no longer necessary
        let(:query_limit) { 2 }
      end
    end

    context 'we need to update the slug, but not the title' do
      let(:old_title) { title }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as the base case, without 2-5 which are no longer necessary
        let(:query_limit) { 6 }
      end
    end

    context 'we need to update the title, but not the slug' do
      let(:last_known_slug) { wiki_page.slug }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as the base case, without 2-5 which are no longer necessary
        let(:query_limit) { 6 }
      end
    end

    context 'we need to update the title and the slug' do
      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as the base case, without 2-5 which are no longer necessary
        let(:query_limit) { 6 }
      end
    end
  end
end
