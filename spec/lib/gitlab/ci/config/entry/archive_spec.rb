# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Archive do
  let(:entry) { described_class.new(config) }
  let(:class_name) { described_class.name.demodulize.underscore }

  describe 'validations' do
    it_behaves_like 'archivable validations'
  end
end
