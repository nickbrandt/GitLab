# frozen_string_literal: true

module Gitlab
  class GeoLogger < Gitlab::Logger
    def self.file_name_noext
      'geo'
    end
  end
end
