# frozen_string_literal: true

module API
  class ProjectAccessTokens < Grape::API::Instance
    include PaginationParams

    before { authenticate! }

    # get all PATs for a project
    # get one specific PAT by ID
    # create new PAT with params
    # revoke/delete a PAT by ID
    # since PATs can't be updated through the UI, won't make a puts


  end
end