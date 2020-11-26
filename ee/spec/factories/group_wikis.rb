# frozen_string_literal: true

FactoryBot.define do
  factory :group_wiki, parent: :wiki do
    transient do
      group { association(:group) }
    end

    container { group }
  end

  factory :group_wiki_page_meta, class: 'GroupWikiPage::Meta' do
    title { generate(:wiki_page_title) }
    group { association(:group) }

    trait :for_wiki_page do
      transient do
        wiki_page { association(:wiki_page, container: group) }
      end

      group { @overrides[:wiki_page]&.container || association(:group) }
      title { wiki_page.title }

      initialize_with do
        raise 'Metadata only available for valid pages' unless wiki_page.valid?

        GroupWikiPage::Meta.find_or_create(wiki_page.slug, wiki_page)
      end
    end
  end

  factory :group_wiki_page_slug, class: 'GroupWikiPage::Slug' do
    group_wiki_page_meta { association(:group_wiki_page_meta) }
    slug { generate(:sluggified_title) }
    canonical { false }

    trait :canonical do
      canonical { true }
    end
  end
end
