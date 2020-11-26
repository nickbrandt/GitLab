# frozen_string_literal: true

module Resolvers
  module Ci
    class ConfigResolver < BaseResolver
      type Types::Ci::Config::ConfigType, null: true

      argument :content, GraphQL::STRING_TYPE,
               required: true,
               description: 'Contents of .gitlab-ci.yml'

      def resolve(content:)
        result = ::Gitlab::Ci::YamlProcessor.new(content).execute

        if result.errors.empty?
          stages = process_stage_groups(result.stages, result.jobs)

          response = {
                        status: :valid,
                        errors: [],
                        stages: stages.select { |stage| !stage[:groups].empty? }
                     }
        else
          response = {
                        status: :invalid,
                        errors: [result.errors.first]
                     }
        end

        response.tap do |response|
          response[:merged_yaml] = result.merged_yaml
        end
      end

      private

      def process_stages(config_stages)
        config_stages.map { |stage| { name: stage, groups: [] } }
      end

      def process_jobs(config_jobs)
        config_jobs.map do |job_name, job|
          {
            name: job_name,
            stage: job[:stage],
            group_name: CommitStatus.new(name: job_name).group_name,
            needs: process_needs(job) || []
          }
        end
      end

      def process_needs(job)
        job.dig(:needs, :job)&.map do |job_need|
          { name: job_need[:name], artifacts: job_need[:artifacts] }
        end
      end

      def process_groups(job_data)
        jobs = process_jobs(job_data)

        group_names = jobs.map { |job| job[:group_name] }.uniq
        jobs_by_group = jobs.group_by { |job| job[:group_name] }
        group_names.map do |group|
          group_jobs = jobs_by_group[group]
          { jobs: group_jobs, name: group, stage: group_jobs.first[:stage], size: group_jobs.count }
        end
      end

      def process_stage_groups(stage_data, job_data)
        stages = process_stages(stage_data)
        groups = process_groups(job_data)

        groups_by_stage = groups.group_by { |group| group[:stage] }
        stages.each do |stage|
          next unless groups_by_stage[stage[:name]]

          stage[:groups] = groups_by_stage[stage[:name]]
        end
      end
    end
  end
end
