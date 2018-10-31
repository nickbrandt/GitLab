# frozen_string_literal: true

class PersonalSnippet < Snippet
  prepend EE::PersonalSnippet

  include WithUploads
end
