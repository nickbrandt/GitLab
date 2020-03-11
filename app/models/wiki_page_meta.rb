# frozen_string_literal: true

class WikiPageMeta < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  belongs_to :project

  has_many :slugs, class_name: 'WikiPageSlug', inverse_of: :wiki_page_meta
  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  validates :title, presence: true
  validates :project_id, presence: true

  alias_method :resource_parent, :project

  # Return the (updated) WikiPageMeta record for a given wiki page
  #
  # If none is found, then a new record is created, and its fields are set
  # to reflect the wiki_page passed.
  #
  # @param [String] last_known_slug
  # @param [WikiPage] wiki_page
  #
  # As with all `find_or_create` methods, this one raises errors on
  # validation issues.
  def self.find_or_create(last_known_slug, wiki_page)
    project = wiki_page.wiki.project

    meta = find_by_canonical_slug(last_known_slug, project) || create(title: wiki_page.title, project_id: project.id)

    meta.update_wiki_page_attributes(wiki_page)
    meta.insert_slugs([last_known_slug, wiki_page.slug], wiki_page.slug)
    meta.canonical_slug = wiki_page.slug

    meta
  end

  def update_wiki_page_attributes(page)
    update_column(:title, page.title) unless page.title == title
  end

  def insert_slugs(strings, canonical)
    slug_attrs = strings.uniq.map do |slug|
      { wiki_page_meta_id: id, slug: slug, canonical: slug == canonical }
    end
    slugs.insert_all(slug_attrs)
  end

  def self.find_by_canonical_slug(canonical_slug, project)
    meta = joins(:slugs).find_by(project_id: project.id,
                                 wiki_page_slugs: { canonical: true, slug: canonical_slug })

    # Prevent queries for canonical_slug
    meta.instance_variable_set(:@canonical_slug, canonical_slug) if meta

    meta
  end

  def canonical_slug
    strong_memoize(:canonical_slug) { slugs.canonical.first&.slug }
  end

  def canonical_slug=(slug)
    return if @canonical_slug == slug

    if persisted?
      page_slug = slugs.find_or_create_by(slug: slug)
      slugs.update_all(['canonical = id in (?)', [page_slug.id]])
    else
      slugs.new(slug: slug, canonical: true)
    end

    @canonical_slug = slug
  end
end
