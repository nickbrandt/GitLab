# frozen_string_literal: true

require 'spec_helper'

describe ScimPaginatable do
  let(:paginatable_class) { Identity }

  describe 'scim_paginate' do
    let(:start_index) { 1 }
    let(:count) { 1 }

    it 'paginates with offset and limit' do
      expect(paginatable_class).to receive_message_chain(:offset, :limit)

      paginatable_class.scim_paginate(start_index: start_index, count: count)
    end

    it 'translates a 1-based index to an offset of 0' do
      expect(paginatable_class).to receive(:offset).with(0).and_return(double(limit: double))

      paginatable_class.scim_paginate(start_index: start_index, count: count)
    end
  end
end
