# frozen_string_literal: true

require 'ostruct'

FactoryBot.define do
  factory :wiki_page do
    transient do
      title { 'Title.with.dot' }
      content { 'Content for wiki page' }
      format { 'markdown' }
      project { create(:project) }
      attrs do
        {
          title: title,
          content: content,
          format: format
        }
      end
    end

    page { OpenStruct.new(url_path: 'some-name') }
    wiki { build(:project_wiki, project: project) }

    initialize_with { new(wiki, page) }

    before(:create) do |page, evaluator|
      page.attributes = evaluator.attrs
    end

    to_create do |page|
      page.create
    end
  end
end
