# frozen_string_literal: true

class WikiPage
  class Slug < ApplicationRecord
    self.table_name = 'wiki_page_slugs'

    belongs_to :wiki_page_meta, class_name: 'WikiPage::Meta', inverse_of: :slugs

    validates :slug, presence: true, uniqueness: { scope: :wiki_page_meta_id }
    validate :only_one_slug_can_be_canonical_per_meta_record

    scope :canonical, -> { where(canonical: true) }

    private

    def only_one_slug_can_be_canonical_per_meta_record
      return unless canonical?

      if other_slugs.canonical.exists?
        errors.add(:canonical, 'Only one slug can be canonical per wiki metadata record')
      end
    end

    def other_slugs
      self.class.unscoped.where(wiki_page_meta_id: wiki_page_meta_id)
    end
  end
end
