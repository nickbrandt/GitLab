# frozen_string_literal: true
require 'rails_helper'

describe DesignManagement::DesignVersion do
  describe 'relations' do
    it { is_expected.to belong_to(:design) }
    it { is_expected.to belong_to(:version) }
  end
end
