# frozen_string_literal: true

module EE
  module API
    module Endpoints
      extend ActiveSupport::Concern

      prepended do
        mount ::EE::API::Boards
        mount ::EE::API::GroupBoards

        mount ::API::Unleash
        mount ::API::EpicIssues
        mount ::API::EpicLinks
        mount ::API::Epics
        mount ::API::Geo
        mount ::API::GeoNodes
        mount ::API::IssueLinks
        mount ::API::Ldap
        mount ::API::LdapGroupLinks
        mount ::API::License
        mount ::API::ProjectMirror
        mount ::API::ProjectPushRule
        mount ::API::MavenPackages
        mount ::API::NpmPackages
        mount ::API::Packages
        mount ::API::PackageFiles
      end
    end
  end
end
