# frozen_string_literal: true

require 'spec_helper'

describe DraftNote do
  include RepoHelpers

  describe 'validations' do
    it_behaves_like 'a valid diff positionable note', :draft_note
  end
end
