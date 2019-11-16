# frozen_string_literal: true

module QA
  module EE
    module Page
      module Dashboard
        module Projects
          def self.prepended(page)
            page.module_eval do
              view 'app/views/shared/projects/_list.html.haml' do
                element :projects_list
              end
            end
          end

          def wait_for_project_replication(project_name)
            wait(max: Runtime::Geo.max_db_replication_time) do
              filter_by_name(project_name)

              within_element(:projects_list) do
                has_text?(project_name)
              end
            end
          end

          def projects_list
            find_element(:projects_list)
          end

          def project_created?(project_name)
            fill_element(:project_filter_form, project_name)

            wait(max: Runtime::Geo.max_db_replication_time) do
              within_element(:projects_list) do
                has_text?(project_name)
              end
            end
          end

          def project_deleted?(project_name)
            fill_element(:project_filter_form, project_name)

            wait(max: Runtime::Geo.max_db_replication_time) do
              within_element(:projects_list) do
                has_no_text?(project_name)
              end
            end
          end
        end
      end
    end
  end
end
