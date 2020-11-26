# frozen_string_literal: true

module GroupWikiPage
  class Meta < ApplicationRecord
    include HasWikiPageMetaAttributes

    self.table_name = 'group_wiki_page_meta'

    belongs_to :group

    has_many :slugs, class_name: 'GroupWikiPage::Slug', foreign_key: 'group_wiki_page_meta_id', inverse_of: :group_wiki_page_meta

    validates :group_id, presence: true

    alias_method :resource_parent, :group

    def self.container_key
      :group_id
    end
  end
end
