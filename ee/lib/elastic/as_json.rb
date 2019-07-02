# frozen_string_literal: true
# Defer evaluation from class-definition time to index-creation time
module Elastic
  class AsJSON
    def initialize(&blk)
      @blk = blk
    end

    def call
      @blk.call
    end

    def as_json(*args, &blk)
      call
    end
  end
end
