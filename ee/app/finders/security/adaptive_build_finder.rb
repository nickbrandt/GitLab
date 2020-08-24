# frozen_string_literal: true

module Security
  class AdaptiveBuildFinder
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20
    ORDERED_CONFIDENCE_LEVELS = %w(confirmed high unknown experimental medium low ignore)
    ORDERED_SEVERITIES = %w(critical high unknown medium low info)

    def initialize(pipeline, params)
      self.pipeline = pipeline
      self.params = params
    end

    def perform
      ladder
    end

    private

    attr_accessor :pipeline, :params

    def ladder
      cursor = 0
      builds = []

      severities.each do |severity|
        confidence_levels.each do |confidence_level|
          security_scans.each do |security_scan|
            stat_value = security_scan.severity_stats.dig(severity, confidence_level).to_i

            if stat_value > 0
              cursor += stat_value

              if cursor >= from
                builds << security_scan.build
              end
            end

            return builds if cursor >= to
          end
        end
      end

      builds
    end

    def security_scans
      @security_scans ||= pipeline.security_scans
                                  .by_scan_types(report_types)
                                  .ordered
                                  .select { |scan| scan.has_finding_for?(severities, confidence_levels) }
    end

    def from
      per_page * (page - 1)
    end

    def to
      per_page * page
    end

    def page
      params.fetch(:page, DEFAULT_PAGE)
    end

    def per_page
      params.fetch(:per_page, DEFAULT_PER_PAGE)
    end

    def report_types
      params[:report_types]
    end

    def severities
      @severities ||= ORDERED_SEVERITIES & params[:severities]
    end

    def confidence_levels
      @confidence_levels ||= ORDERED_CONFIDENCE_LEVELS & params[:confidence_levels]
    end
  end
end
