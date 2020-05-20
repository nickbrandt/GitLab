# frozen_string_literal: true

class Admin::Geo::PackageFilesController < Admin::Geo::ApplicationController
  before_action :check_license!

  def index
  end
end
