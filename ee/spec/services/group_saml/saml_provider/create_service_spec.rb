# frozen_string_literal: true

require 'spec_helper'

describe GroupSaml::SamlProvider::CreateService do
  subject(:service) { described_class.new(nil, group, params: params) }

  let(:group) { create :group }

  include_examples 'base SamlProvider service'
end
