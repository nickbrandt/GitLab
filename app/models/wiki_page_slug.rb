# frozen_string_literal: true

class WikiPageSlug < ApplicationRecord
  belongs_to :wiki_page_meta

  validates :slug, presence: true, uniqueness: { scope: :wiki_page_meta_id }
  validate :only_one_slug_can_be_canonical_per_meta_record

  scope :canonical, -> { where(canonical: true) }

  def canonical?
    canonical
  end

  private

  def only_one_slug_can_be_canonical_per_meta_record
    return unless canonical?

    if other_slugs.canonical.exists?
      errors.add(:canonical, 'Only one slug can be canonical per wiki metadata record')
    end
  end

  def other_slugs
    self.class.where(wiki_page_meta_id: wiki_page_meta_id)
  end
end
