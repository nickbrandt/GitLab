# frozen_string_literal: true

class PersonalSnippet < Snippet
  include WithUploads
end

PersonalSnippet.prepend_if_ee('EE::PersonalSnippet')
