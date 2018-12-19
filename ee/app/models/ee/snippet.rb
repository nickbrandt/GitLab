# frozen_string_literal: true

module EE
  module Snippet
    extend ActiveSupport::Concern

    prepended do
      include Elastic::SnippetsSearch
    end
  end
end
