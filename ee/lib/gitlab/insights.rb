# frozen_string_literal: true

module Gitlab
  module Insights
    CONFIG_FILE_PATH = '.gitlab/insights.yml'
    COLOR_SCHEME = {
      red: '#e6194b',
      green: '#3cb44b',
      yellow: '#ffe119',
      blue: '#4363d8',
      orange: '#f58231',
      purple: '#911eb4',
      cyan: '#42d4f4',
      magenta: '#f032e6',
      lime: '#bfef45',
      pink: '#fabebe',
      teal: '#469990',
      lavender: '#e6beff',
      brown: '#9a6324',
      beige: '#fffac8',
      maroon: '#800000',
      mint: '#aaffc3',
      olive: '#808000',
      apricot: '#ffd8b1'
    }.freeze

    UNCATEGORIZED = 'undefined'
    UNCATEGORIZED_COLOR = "#808080"
    TOP_COLOR = "#ff0000"
    HIGH_COLOR = "#ff8800"
    MEDIUM_COLOR = "#fff600"
    LOW_COLOR = "#008000"
    BUG_COLOR = "#ff0000"
    SECURITY_COLOR = "#d9534f"
    DEFAULT_COLOR = "#428bca"
    LINE_COLOR = COLOR_SCHEME[:red]

    STATIC_COLOR_MAP = {
      UNCATEGORIZED => UNCATEGORIZED_COLOR,
      "S1" => TOP_COLOR,
      "S2" => HIGH_COLOR,
      "S3" => MEDIUM_COLOR,
      "S4" => LOW_COLOR,
      "P1" => TOP_COLOR,
      "P2" => HIGH_COLOR,
      "P3" => MEDIUM_COLOR,
      "P4" => LOW_COLOR,
      "bug" => BUG_COLOR,
      "security" => SECURITY_COLOR
    }.freeze
  end
end
