# frozen_string_literal: true

module EE
  module WikiPages
    module EventCreateService
      extend ::Gitlab::Utils::Override

      private

      override :find_or_create_wiki_page_meta
      def find_or_create_wiki_page_meta(slug, page)
        if page.container.is_a?(Group)
          GroupWikiPage::Meta.find_or_create(slug, page)
        else
          super(slug, page)
        end
      end
    end
  end
end
