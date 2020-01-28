# frozen_string_literal: true

# :nocov:
module DeliverNever
  refine ActionMailer::MessageDelivery do
    def deliver_later
      self
    end
  end
end

module MuteNotifications
  refine NotificationService do
    def new_note(note)
    end
  end
end

module Gitlab
  class Seeder
    extend ActionView::Helpers::NumberHelper

    MASS_INSERT_PROJECT_START = 'mass_insert_project_'
    MASS_INSERT_USER_START = 'mass_insert_user_'
    ESTIMATED_INSERT_PER_MINUTE = 2_000_000
    MASS_INSERT_ENV = 'MASS_INSERT'

    def self.not_mass_generated_users
      User.where.not("username LIKE '#{MASS_INSERT_USER_START}%'") # rubocop:disable CodeReuse/ActiveRecord
    end

    def self.not_mass_generated_projects
      Project.where.not("path LIKE '#{MASS_INSERT_PROJECT_START}%'") # rubocop:disable CodeReuse/ActiveRecord
    end

    def self.with_mass_insert(size, model)
      humanized_model_name = model.is_a?(String) ? model : model.model_name.human.pluralize(size)

      if !ENV[MASS_INSERT_ENV] && !ENV['CI']
        puts "\nSkipping mass insertion for #{humanized_model_name}."
        puts "Consider running the seed with #{MASS_INSERT_ENV}=1"
        return
      end

      humanized_size = number_with_delimiter(size)
      estimative = estimated_time_message(size)

      puts "\nCreating #{humanized_size} #{humanized_model_name}."
      puts estimative

      yield

      puts "\n#{number_with_delimiter(size)} #{humanized_model_name} created!"
    end

    def self.estimated_time_message(size)
      estimated_minutes = (size.to_f / ESTIMATED_INSERT_PER_MINUTE).round
      humanized_minutes = 'minute'.pluralize(estimated_minutes)

      if estimated_minutes.zero?
        "Rough estimated time: less than a minute ⏰"
      else
        "Rough estimated time: #{estimated_minutes} #{humanized_minutes} ⏰"
      end
    end

    using MuteNotifications
    using DeliverNever

    def self.quiet
      # Disable database insertion logs so speed isn't limited by ability to print to console
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      SeedFu.quiet = true

      yield self

      SeedFu.quiet = false
      ActiveRecord::Base.logger = old_logger
      puts "\nOK".color(:green)
    end
  end
end
# :nocov:
