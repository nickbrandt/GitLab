# frozen_string_literal: true

class CountriesController < ActionController::Metal
  include AbstractController::Rendering
  include ActionController::Renderers::All

  def index
    countries = World.countries_for_select

    render json: countries, status: (countries ? :ok : :not_found)
  end
end
