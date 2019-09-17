# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Rules::Rule::Clause::Changes do
  describe 'satisfied_by?' do
    let(:pipeline) { build(:ci_pipeline) }
    subject { described_class.new(globs) }

    before do
      allow(pipeline).to receive(:modified_paths).and_return(files.keys)
    end

    it_behaves_like 'a glob matching rule'
  end
end
