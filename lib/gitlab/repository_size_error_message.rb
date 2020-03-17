# frozen_string_literal: true

module Gitlab
  class RepositorySizeErrorMessage
    include ActiveSupport::NumberHelper

    delegate :current_size, :limit, to: :@checker

    # @param checher [RepositorySizeChecker]
    def initialize(checker)
      @checker = checker
    end

    def commit_error
      "Your changes could not be committed, #{base_message}"
    end

    def merge_error
      "This merge request cannot be merged, #{base_message}"
    end

    def push_error(exceeded_size = nil)
      "Your push has been rejected, #{base_message(exceeded_size)}. #{more_info_message}"
    end

    def new_changes_error
      "Your push to this repository would cause it to exceed the size limit of #{formatted(limit)} so it has been rejected. #{more_info_message}"
    end

    def more_info_message
      'Please contact your GitLab administrator for more information.'
    end

    def above_size_limit_message
      "The size of this repository (#{formatted(current_size)}) exceeds the limit of #{formatted(limit)} by #{formatted(size_to_remove)}. You won't be able to push new code to this project. #{more_info_message}"
    end

    private

    def base_message(exceeded_size = nil)
      "because this repository has exceeded its size limit of #{formatted(limit)} by #{formatted(size_to_remove(exceeded_size))}"
    end

    def size_to_remove(exceeded_size = nil)
      exceeded_size || checker.exceeded_size
    end

    def formatted(number)
      number_to_human_size(number, delimiter: ',', precision: 2)
    end
  end
end
