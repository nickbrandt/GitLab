# frozen_string_literal: true

module Vulnerabilities
  class LetterGrade
    LETTER_GRADE_CONDITIONS = {
      a: 'critical = 0 and high = 0 and unknown = 0 and medium = 0 and low = 0',
      b: 'critical = 0 and high = 0 and unknown = 0 and medium = 0 and low > 0',
      c: 'critical = 0 and high = 0 and unknown = 0 and medium > 0',
      d: 'critical = 0 and (high > 0 or unknown > 0)',
      f: 'critical > 0'
    }.with_indifferent_access.freeze

    class << self
      def for(vulnerable)
        raise "#{vulnerable.inspect} does not respond_to `projects`" unless vulnerable.respond_to?(:projects)

        project_ids_filter = vulnerable.projects.select(:id)
        from_clause = Vulnerabilities::Stats.with_stats_schema.where(project_id: project_ids_filter).to_sql
        sql_query = letter_grades_sql_for(from_clause)

        fetch_letter_grades(vulnerable, sql_query)
      end

      private

      delegate :connection, to: ActiveRecord::Base, private: true

      def letter_grades_sql_for(from_clause)
        "SELECT #{count_clauses} FROM (#{from_clause}) as stats"
      end

      def count_clauses
        @count_clauses ||= LETTER_GRADE_CONDITIONS.map do |letter, condition|
          "count(*) filter (where #{condition}) as #{letter}"
        end.join(', ')
      end

      def fetch_letter_grades(vulnerable, sql_query)
        connection.execute(sql_query).first.map do |letter, count|
          new(vulnerable, letter, count)
        end
      end
    end

    attr_reader :vulnerable, :letter, :count

    def initialize(vulnerable, letter, count)
      @vulnerable = vulnerable
      @letter = letter
      @count = count
    end

    def projects
      vulnerable.projects.where(id: projects_filter)
    end

    def ==(other)
      vulnerable == other.vulnerable &&
        letter == other.letter &&
        count == other.count
    end

    private

    def projects_filter
      Vulnerabilities::Stats.select(:project_id)
                            .from(Vulnerabilities::Stats.with_stats_schema)
                            .where(letter_grade_condition)
    end

    def letter_grade_condition
      LETTER_GRADE_CONDITIONS[letter]
    end
  end
end
