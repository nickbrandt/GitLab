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
        autoload :DesignManagement, 'qa/ee/page/component/design_management'
        autoload :LicenseManagement, 'qa/ee/page/component/license_management'

        module IssueBoard
          autoload :Show, 'qa/ee/page/component/issue_board/show'
        end

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
        autoload :SamlSSOSignUp, 'qa/ee/page/group/saml_sso_sign_up'
        autoload :Members, 'qa/ee/page/group/members'
        autoload :ContributionAnalytics, 'qa/ee/page/group/contribution_analytics'

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

        module Monitoring
          autoload :AuditLog, 'qa/ee/page/admin/monitoring/audit_log.rb'
        end

        module Settings
          autoload :Templates, 'qa/ee/page/admin/settings/templates'
          autoload :Integration, 'qa/ee/page/admin/settings/integration'
          autoload :Preferences, 'qa/ee/page/admin/settings/preferences'

          module Component
            autoload :Email, 'qa/ee/page/admin/settings/component/email'
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
          autoload :Packages, 'qa/ee/page/project/sub_menus/packages'
          autoload :SecurityCompliance, 'qa/ee/page/project/sub_menus/security_compliance'
          autoload :Repository, 'qa/ee/page/project/sub_menus/repository'
          autoload :Settings, 'qa/ee/page/project/sub_menus/settings'
          autoload :Project, 'qa/ee/page/project/sub_menus/project'
        end

        module Issue
          autoload :Index, 'qa/ee/page/project/issue/index'
          autoload :Show, 'qa/ee/page/project/issue/show'
        end

        module Wiki
          autoload :Show, 'qa/ee/page/project/wiki/show'
        end

        module Milestone
          autoload :Show, 'qa/ee/page/project/milestone/show'
        end

        module Settings
          autoload :ProtectedBranches, 'qa/ee/page/project/settings/protected_branches'
          autoload :MirroringRepositories, 'qa/ee/page/project/settings/mirroring_repositories'
          autoload :MergeRequest, 'qa/ee/page/project/settings/merge_request'
          autoload :Integrations, 'qa/ee/page/project/settings/integrations'
          autoload :Repository, 'qa/ee/page/project/settings/repository'
          autoload :PushRules, 'qa/ee/page/project/settings/push_rules'
          autoload :CICD, 'qa/ee/page/project/settings/ci_cd.rb'
          autoload :LicenseCompliance, 'qa/ee/page/project/settings/license_compliance.rb'

          module Services
            autoload :Jenkins, 'qa/ee/page/project/settings/services/jenkins'
          end
        end

        module Operations
          module Kubernetes
            autoload :Show, 'qa/ee/page/project/operations/kubernetes/show'
          end
        end

        module Packages
          autoload :Index, 'qa/ee/page/project/packages/index'
          autoload :Show, 'qa/ee/page/project/packages/show'
        end

        module Pipeline
          autoload :Show, 'qa/ee/page/project/pipeline/show'
        end

        module Secure
          autoload :Show, 'qa/ee/page/project/secure/show'
          autoload :DependencyList, 'qa/ee/page/project/secure/dependency_list'
        end

        module PathLocks
          autoload :Index, 'qa/ee/page/project/path_locks/index'
        end
      end

      module MergeRequest
        autoload :New, 'qa/ee/page/merge_request/new'
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
      autoload :License, 'qa/ee/resource/license'
      autoload :Epic, 'qa/ee/resource/epic'
      autoload :ProjectMilestone, 'qa/ee/resource/project_milestone'
      autoload :GroupLabel, 'qa/ee/resource/group_label.rb'

      module Board
        autoload :BaseBoard, 'qa/ee/resource/board/base_board'
        autoload :GroupBoard, 'qa/ee/resource/board/group_board'
        autoload :ProjectBoard, 'qa/ee/resource/board/project_board'

        module BoardList
          module Group
            autoload :BoardList, 'qa/ee/resource/board/board_list/group/board_list'
          end

          module Project
            autoload :BaseBoardList, 'qa/ee/resource/board/board_list/project/base_board_list'
            autoload :LabelBoardList, 'qa/ee/resource/board/board_list/project/label_board_list'
            autoload :MilestoneBoardList, 'qa/ee/resource/board/board_list/project/milestone_board_list'
          end
        end
      end

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
