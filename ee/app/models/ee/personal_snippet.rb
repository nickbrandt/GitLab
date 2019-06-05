# frozen_string_literal: true

module EE
  module PersonalSnippet
    extend ActiveSupport::Concern

    prepended do
      include Elastic::SnippetsSearch
    end
  end
end
