# frozen_string_literal: true

class ReviewAppSetupEntity < Grape::Entity
  include RequestAwareEntity

  expose :can_setup_review_app?

  expose :clusters_empty?, if: -> (_, _) { project.can_setup_review_app? } do |project|
    project.clusters_empty?
  end

  expose :review_snippet, if: -> (_, _) { project.can_setup_review_app? } do |_|
    YAML.safe_load(File.read(Rails.root.join('lib', 'gitlab', 'ci', 'snippets', 'review_app_default.yml'))).inspect
  end

  private

  def current_user
    request.current_user
  end

  def project
    object
  end
end
