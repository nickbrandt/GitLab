module QA
  ##
  # GitLab EE extensions
  #
  module EE
    module Runtime
      autoload :Env, 'qa/ee/runtime/env'
      autoload :Geo, 'qa/ee/runtime/geo'
      autoload :Saml, 'qa/ee/runtime/saml'
    end

    module Page
      module Dashboard
        autoload :Projects, 'qa/ee/page/dashboard/projects'
      end

      module Group
        autoload :Menu, 'qa/ee/page/group/menu'
        autoload :SamlSSOSignIn, 'qa/ee/page/group/saml_sso_sign_in'
        autoload :Members, 'qa/ee/page/group/members'

        module Settings
          autoload :SamlSSO, 'qa/ee/page/group/settings/saml_sso'
          autoload :LDAPSync, 'qa/ee/page/group/settings/ldap_sync'
          autoload :General, 'qa/ee/page/group/settings/general'
        end
      end

      module File
        autoload :Show, 'qa/ee/page/file/show'
      end

      module Main
        autoload :Banner, 'qa/ee/page/main/banner'
      end

      module Admin
        autoload :Menu, 'qa/ee/page/admin/menu'
        autoload :License, 'qa/ee/page/admin/license'

        module Geo
          module Nodes
            autoload :Show, 'qa/ee/page/admin/geo/nodes/show'
            autoload :New, 'qa/ee/page/admin/geo/nodes/new'
          end
        end
      end

      module Profile
        autoload :Menu, 'qa/ee/page/profile/menu'
      end

      module Project
        autoload :New, 'qa/ee/page/project/new'
        autoload :Show, 'qa/ee/page/project/show'

        module Issue
          autoload :Index, 'qa/ee/page/project/issue/index'
          autoload :Show, 'qa/ee/page/project/issue/show'
        end

        module Settings
          autoload :ProtectedBranches, 'qa/ee/page/project/settings/protected_branches'
          autoload :MirroringRepositories, 'qa/ee/page/project/settings/mirroring_repositories'
        end
      end

      module MergeRequest
        autoload :Show, 'qa/ee/page/merge_request/show'
      end

      module Group
        module Epic
          autoload :Index, 'qa/ee/page/group/epic/index'
          autoload :Show, 'qa/ee/page/group/epic/show'
          autoload :Edit, 'qa/ee/page/group/epic/edit'
        end
      end
    end

    module Resource
      autoload :License, 'qa/ee/resource/license'
      autoload :Epic, 'qa/ee/resource/epic'

      module Geo
        autoload :Node, 'qa/ee/resource/geo/node'
      end
    end

    module Scenario
      module Test
        autoload :Geo, 'qa/ee/scenario/test/geo'
        module Integration
          autoload :GroupSAML, 'qa/ee/scenario/test/integration/group_saml'
        end
      end
    end
  end
end
