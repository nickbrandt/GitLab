# frozen_string_literal: true

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
      module Component
        module WebIDE
          autoload :WebTerminalPanel, 'qa/ee/page/component/web_ide/web_terminal_panel'
        end
      end

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

        module Settings
          autoload :Templates, 'qa/ee/page/admin/settings/templates'
          autoload :Integration, 'qa/ee/page/admin/settings/integration'

          module Component
            autoload :Elasticsearch, 'qa/ee/page/admin/settings/component/elasticsearch'
          end
        end
      end

      module Profile
        autoload :Menu, 'qa/ee/page/profile/menu'
      end

      module Project
        autoload :New, 'qa/ee/page/project/new'
        autoload :Show, 'qa/ee/page/project/show'
        autoload :Menu, 'qa/ee/page/project/menu'

        module SubMenus
          autoload :SecurityCompliance, 'qa/ee/page/project/sub_menus/security_compliance'
        end

        module Issue
          autoload :Index, 'qa/ee/page/project/issue/index'
          autoload :Show, 'qa/ee/page/project/issue/show'

          module Board
            autoload :Show, 'qa/ee/page/project/issue/board/show'
          end
        end

        module Settings
          autoload :ProtectedBranches, 'qa/ee/page/project/settings/protected_branches'
          autoload :MirroringRepositories, 'qa/ee/page/project/settings/mirroring_repositories'
          autoload :Main, 'qa/ee/page/project/settings/main'
          autoload :MergeRequestApproval, 'qa/ee/page/project/settings/merge_request_approval'
        end

        module Operations
          module Kubernetes
            autoload :Show, 'qa/ee/page/project/operations/kubernetes/show'
          end
        end

        module Pipeline
          autoload :Show, 'qa/ee/page/project/pipeline/show'
        end

        module Secure
          autoload :Show, 'qa/ee/page/project/secure/show'
          autoload :DependencyList, 'qa/ee/page/project/secure/dependency_list'
        end
      end

      module MergeRequest
        autoload :Show, 'qa/ee/page/merge_request/show'
      end

      module Group
        autoload :IssuesAnalytics, 'qa/ee/page/group/issues_analytics'
        autoload :Roadmap, 'qa/ee/page/group/roadmap'

        module Epic
          autoload :Index, 'qa/ee/page/group/epic/index'
          autoload :Show, 'qa/ee/page/group/epic/show'
          autoload :Edit, 'qa/ee/page/group/epic/edit'
        end

        module Secure
          autoload :Show, 'qa/ee/page/group/secure/show'
        end
      end

      module Insights
        autoload :Show, 'qa/ee/page/insights/show'
      end
    end

    module Resource
      autoload :Board, 'qa/ee/resource/board'
      autoload :LabelBoardList, 'qa/ee/resource/label_board_list'
      autoload :MilestoneBoardList, 'qa/ee/resource/milestone_board_list'
      autoload :License, 'qa/ee/resource/license'
      autoload :Epic, 'qa/ee/resource/epic'
      autoload :ProjectMilestone, 'qa/ee/resource/project_milestone'

      module Geo
        autoload :Node, 'qa/ee/resource/geo/node'
      end

      module Settings
        autoload :Elasticsearch, 'qa/ee/resource/settings/elasticsearch'
      end
    end

    module Scenario
      module Test
        autoload :Geo, 'qa/ee/scenario/test/geo'
        module Integration
          autoload :GroupSAML, 'qa/ee/scenario/test/integration/group_saml'
          autoload :Elasticsearch, 'qa/ee/scenario/test/integration/elasticsearch'
        end

        module Sanity
          autoload :Selectors, 'qa/ee/scenario/test/sanity/selectors'
        end
      end
    end
  end
end
