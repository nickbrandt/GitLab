# frozen_string_literal: true

class Gitlab::FileUpload < SimpleDelegator
  attr_accessor :original_filename
end
