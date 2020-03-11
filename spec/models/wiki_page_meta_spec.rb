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
      described_class.create!(
        title: old_title,
        project: project,
        canonical_slug: last_known_slug
      )
    end

    shared_examples 'metadata examples' do
      it 'establishes the correct state', :aggregate_failures do
        meta = find_record

        expect(meta).to have_attributes(
          canonical_slug: wiki_page.slug,
          title: wiki_page.title,
          project: wiki_page.wiki.project
        )
        expect(meta.slugs.where(slug: last_known_slug)).to exist
        expect(meta.slugs.canonical.where(slug: wiki_page.slug)).to exist
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
        # The base case is 7 queries:
        #  - 1 to find the metadata object if it exists
        #  - 1 to create it if it does not
        #  - 2 for 1 savepoint
        #  - 1 to insert last_known_slug and current_slug
        #  - 1 to find the current slug
        #  - 1 to set canonical status correctly
        #
        # (Log has been edited for clarity)
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        # SAVEPOINT active_record_2
        # INSERT INTO wiki_page_meta (project_id, title) VALUES (?, ?) RETURNING id
        # RELEASE SAVEPOINT active_record_2
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug)
        #   VALUES (?, ?) (?, ?)
        #   ON CONFLICT  DO NOTHING RETURNING id
        # SELECT * FROM wiki_page_slugs
        #   WHERE wiki_page_meta_id = ? AND slug = ? LIMIT 1
        # UPDATE wiki_page_slugs
        #   SET canonical = id in (?)
        #   WHERE wiki_page_meta_id = ? AND id != 4
        let(:query_limit) { 7 }
      end
    end

    context 'the last_known_slug is the same as the current slug, as on creation' do
      let(:last_known_slug) { current_slug }

      include_examples 'metadata examples' do
        # Identical to the base case.
        let(:query_limit) { 7 }
      end
    end

    context 'a record exists in the DB in the correct state' do
      let(:last_known_slug) { current_slug }
      let(:old_title) { title }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        #
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) ON CONFLICT  DO NOTHING RETURNING id
        let(:query_limit) { 2 }
      end
    end

    context 'we need to update the slug, but not the title' do
      let(:old_title) { title }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as minimal case, plus the additional queries needed to update the
        # slug.
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        #
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) ON CONFLICT  DO NOTHING RETURNING id
        #
        # SELECT * FROM wiki_page_slugs
        #   WHERE wiki_page_slugs.wiki_page_meta_id = ?
        #     AND wiki_page_slugs.slug = ?
        #     LIMIT 1
        #
        # UPDATE wiki_page_slugs SET canonical = id in (?) WHERE wiki_page_meta_id = 2
        let(:query_limit) { 4 }
      end
    end

    context 'we need to update the title, but not the slug' do
      let(:last_known_slug) { wiki_page.slug }

      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as minimal case, plus one query to update the title.
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        #
        # UPDATE wiki_page_meta SET title = ? WHERE id = ?
        #
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) ON CONFLICT  DO NOTHING RETURNING id
        let(:query_limit) { 3 }
      end
    end

    context 'we need to update the title and the slug' do
      before do
        create_previous_version
      end

      include_examples 'metadata examples' do
        # Same as minimal case, plus one for the title, and two for the slug
        #
        # SELECT * FROM wiki_page_meta
        #   INNER JOIN wiki_page_slugs
        #     ON wiki_page_slugs.wiki_page_meta_id = wiki_page_meta.id
        #   WHERE wiki_page_meta.project_id = ?
        #     AND wiki_page_slugs.canonical = TRUE
        #     AND wiki_page_slugs.slug = ?
        #   LIMIT 1
        #
        # UPDATE wiki_page_meta SET title = ? WHERE id = ?
        #
        # INSERT INTO wiki_page_slugs (wiki_page_meta_id,slug,canonical)
        #   VALUES (?, ?, ?) ON CONFLICT  DO NOTHING RETURNING id
        #
        # SELECT * FROM wiki_page_slugs
        #   WHERE wiki_page_slugs.wiki_page_meta_id = ?
        #     AND wiki_page_slugs.slug = ?
        #     LIMIT 1
        #
        # UPDATE wiki_page_slugs SET canonical = id in (?) WHERE wiki_page_meta_id = 2
        let(:query_limit) { 5 }
      end
    end
  end
end
