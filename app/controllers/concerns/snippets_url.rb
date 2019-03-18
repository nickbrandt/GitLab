# frozen_string_literal: true

module SnippetsUrl
  extend ActiveSupport::Concern

  SNIPPETS_SECRET_KEYWORD = 'secret'

  private

  attr_reader :snippet

  def authorize_secret_snippet!
    return unless snippet&.snippet?

    return render_404 unless snippet.valid_secret_token?(params[:token])

    # current_user ? render_404 : authenticate_user!
  end

  # def secrets_match?(secret)
  #   ActiveSupport::SecurityUtils.secure_compare(secret.to_s, snippet.secret_token)
  # end

  # def ensure_complete_url
  #   redirect_to(complete_full_path.to_s) if redirect_to_complete_full_path?
  # end

  # def redirect_to_complete_full_path?
  #   return unless snippet&.secret?

  #   complete_full_path != current_full_path
  # end

  # def complete_full_path
  #   @complete_full_path ||= begin
  #     path = current_full_path.clone
  #     secret_query = { SNIPPETS_SECRET_KEYWORD => snippet.secret_token }
  #     path.query = current_url_query_hash.merge(secret_query).to_query
  #     path
  #   end
  # end

  # def current_full_path
  #   @current_full_path ||= begin
  #     path = URI.parse(current_url.path.chomp('/'))
  #     path.query = current_url_query_hash.to_query unless current_url_query_hash.empty?
  #     path
  #   end
  # end

  # def current_url
  #   @current_url ||= URI.parse(request.original_url)
  # end

  # def current_url_query_hash
  #   @current_url_query_hash ||= Rack::Utils.parse_nested_query(current_url.query)
  # end
end
