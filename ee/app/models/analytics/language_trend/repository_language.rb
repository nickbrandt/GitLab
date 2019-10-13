# frozen_string_literal: true

class Analytics::LanguageTrend::RepositoryLanguage < ApplicationRecord
  belongs_to :programming_language
  belongs_to :project
end
