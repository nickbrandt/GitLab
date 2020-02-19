# frozen_string_literal: true

require 'spec_helper'

describe LabelLink do
  it { expect(build(:label_link)).to be_valid }

  it { is_expected.to belong_to(:label) }
  it { is_expected.to belong_to(:target) }

  def build_valid_items_for_bulk_insertion
    Array.new(10) { build(:label_link) }
  end

  def build_invalid_items_for_bulk_insertion
    [] # class does not have any validations defined
  end

  it_behaves_like 'a BulkInsertSafe model', LabelLink
end
