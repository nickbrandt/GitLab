# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThrottledCleanupContainerRepositoryWorker do
  it_behaves_like 'a cleanup container repository worker'

  it 'has an throttled urgency' do
    expect(described_class.get_urgency).to eq(:throttled)
  end
end
