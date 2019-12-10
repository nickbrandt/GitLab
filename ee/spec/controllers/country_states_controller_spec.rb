# frozen_string_literal: true

require 'spec_helper'

describe CountryStatesController do
  describe 'GET #index' do
    it 'returns a list of states as json' do
      country = 'NL'
      get :index, params: { country: country }

      expected_json = World.states_for_country(country).to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_json)
    end

    it 'returns "null" when the provided country is not found' do
      country = 'NLX'
      get :index, params: { country: country }

      expect(response.status).to eq(404)
      expect(response.body).to eq("null")
    end
  end
end
