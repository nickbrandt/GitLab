# frozen_string_literal: true

module Ci
  class DailyCodeCoverage < ApplicationRecord
    extend Gitlab::Ci::Model

    def self.create_or_update_for_build(build)
      ref = connection.quote(build.ref)
      name = connection.quote(build.name)
      date = connection.quote(build.created_at.to_date)

      connection.execute <<-EOF.strip_heredoc
        INSERT INTO #{table_name} (project_id, ref, name, date, last_build_id, coverage)
        VALUES (#{build.project_id}, #{ref}, #{name}, #{date}, #{build.id}, #{build.coverage})
        ON CONFLICT (project_id, ref, name, date)
        DO UPDATE SET coverage = #{build.coverage}, last_build_id = #{build.id} WHERE #{table_name}.last_build_id < #{build.id};
      EOF
    end
  end
end
