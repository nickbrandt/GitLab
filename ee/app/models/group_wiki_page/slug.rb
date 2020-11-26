# frozen_string_literal: true

module GroupWikiPage
  class Slug < ApplicationRecord
    def self.meta_foreign_key
      :group_wiki_page_meta_id
    end

    include HasWikiPageSlugAttributes

    self.table_name = 'group_wiki_page_slugs'

    belongs_to :group_wiki_page_meta, class_name: 'GroupWikiPage::Meta', inverse_of: :slugs
  end
end
