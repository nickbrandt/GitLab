# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Wiki
          module Show
            def wait_for_repository_replication(max_wait: Runtime::Geo.max_file_replication_time)
              wait_until_geo_max_replication_time(max_wait: max_wait) do
                has_no_text?(/No repository|The wiki for this project is empty/)
              end
            end

            def wait_for_repository_replication_with(text, max_wait: Runtime::Geo.max_file_replication_time)
              wait_until_geo_max_replication_time(max_wait: max_wait) do
                page.has_text?(text)
              end
            end

            def wait_until_geo_max_replication_time(max_wait: Runtime::Geo.max_file_replication_time)
              wait(max: max_wait) { yield }
            end
          end
        end
      end
    end
  end
end
