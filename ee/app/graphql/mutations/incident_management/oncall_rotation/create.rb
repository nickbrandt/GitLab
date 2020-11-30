# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallRotation
      class Create < Base
        include ResolvesProject

        graphql_name 'OncallRotationCreate'

        argument :project_path, GraphQL::ID_TYPE,
                 required: true,
                 description: 'The project to create the on-call schedule in'

        argument :schedule_iid, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The iid of the on-call schedule to create the on-call rotation in'

        argument :name, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The name of the on-call rotation'

        argument :starts_at, Types::IncidentManagement::OncallRotationDateInputType,
                 required: true,
                 description: 'The start date and time of the on-call rotation'

        argument :rotation_length, Types::IncidentManagement::OncallRotationLengthInputType,
                 required: true,
                 description: 'The rotation length of the on-call rotation'

        argument :participant_usernames,
                 [Types::IncidentManagement::OncallUserInputType],
                 required: true,
                 description: 'The usernames to participate in the on-call rotation.'

        def resolve(args)
          project = authorized_find!(full_path: args[:project_path])

          schedule = ::IncidentManagement::OncallSchedulesFinder.new(current_user, project, { iids: args[:schedule_iid] })
                                                                .execute
                                                                .first

          params = prepare_params(args, schedule)

          result = ::IncidentManagement::OncallRotations::CreateService.new(
            schedule,
            project,
            current_user,
            params,
            find_participants(args[:participant_usernames])
          ).execute

          errors = result.error? ? [result.message] : []

          {
            oncall_rotation: result.payload[:oncall_rotation],
            errors: errors
          }
        end

        private

        def prepare_params(args, schedule)
          rotation_length = args[:rotation_length][:length]
          rotation_length_unit = args[:rotation_length][:unit]
          starts_at = parse_start_time(schedule, args)

          args.slice(:name).merge(
            rotation_length: rotation_length,
            rotation_length_unit: rotation_length_unit,
            starts_at: starts_at
          )
        end

        def parse_start_time(schedule, args)
          "#{args[:starts_at][:date]} #{args[:starts_at][:time]}".in_time_zone(schedule.timezone)
        end

        def find_object(full_path:)
          resolve_project(full_path: full_path)
        end

        def find_participants(user_array)
          usernames = user_array.map(&:username)

          matched_users = UsersFinder.new(current_user, username: usernames).execute

          user_array.map do |user|
            matched_user = matched_users.find { |u| u.username == user[:username] }
            next unless matched_user.present?

            user.to_h.merge(user: matched_user)
          end.compact
        end
      end
    end
  end
end
