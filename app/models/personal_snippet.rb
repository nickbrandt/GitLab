# frozen_string_literal: true

class PersonalSnippet < Snippet
  include WithUploads

  before_save :update_secret_token

  def embeddable?
    super || secret?
  end

  alias_method :visibility_secret?, :secret?
  def secret?
    visibility_secret? && secret_token?
  end

  private

  def update_secret_token
    # secret? checks the visibility and also if the token exists
    return if secret?

    # If the visibility is secret assign a random value, otherwise
    # assign a nil value
    self.secret_token = if visibility_secret?
                          SecureRandom.hex
                        end
  end
end
