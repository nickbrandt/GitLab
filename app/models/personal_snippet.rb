# frozen_string_literal: true

class PersonalSnippet < Snippet
  include WithUploads

  before_save :update_secret_snippet_data

  def searchable?
    !secret?
  end

  def self.visibility_level_values(user)
    Gitlab::VisibilityLevel.values.tap do |values|
      values << VISIBILITY_SECRET if Feature.enabled?(:secret_snippets, user)
    end
  end

  private

  # Allow secret to be true only for public snippets
  def snippet_can_be_secret?
    public?
  end

  def update_secret_snippet_data
    self.secret = !!self.secret && snippet_can_be_secret?
    # If the snippet is secret and secret_token is empty we create a new one
    # If the snippet is secret and secret_token is not empty we we leave the existing one
    # If the snippet is not secret we reset the token to nil
    self.secret_token = self.secret ? (self.secret_token || SecureRandom.hex) : nil
  end
end
