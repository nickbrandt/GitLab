# frozen_string_literal: true

require 'securerandom'

class FlipperSession
  SESSION_KEY = '_flipper_id'.freeze

  attr_reader :id

  def initialize(id = generate_id)
    @id = id
  end

  # This method is required by Flipper
  # https://github.com/jnunemaker/flipper/blob/master/docs/Gates.md#2-individual-actor
  def flipper_id
    "flipper_session:#{id}"
  end

  private

  def generate_id
    SecureRandom.uuid
  end
end
