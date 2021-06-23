# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require './spec/support/helpers/test_env'

class Gitlab::Seeder::Burndown
  def initialize(project, perf: false)
    @project = project
  end

  def seed!
    Timecop.travel 10.days.ago

    Sidekiq::Worker.skipping_transaction_check do
      Sidekiq::Testing.inline! do
        create_milestone
        print '.'

        create_issues
        print '.'

        close_issues
        print '.'

        reopen_issues
        print '.'
      end
    end

    Timecop.return

    print '.'
  end

  private

  def create_milestone
    milestone_params = {
      title: "Sprint - #{FFaker::Lorem.sentence}",
      description: FFaker::Lorem.sentence,
      state: 'active',
      start_date: Date.today,
      due_date: rand(5..10).days.from_now
    }

    @milestone = Milestones::CreateService.new(@project, @project.team.users.sample, milestone_params).execute
  end

  def create_issues
    20.times do
      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: 'opened',
        milestone: @milestone,
        assignees: [@project.team.users.sample],
        weight: rand(1..9)
      }

      Issues::CreateService.new(project: @project, current_user: @project.team.users.sample, params: issue_params, spam_params: nil).execute
    end
  end

  def close_issues
    @milestone.start_date.upto(@milestone.due_date) do |date|
      Timecop.travel(date)

      close_number = rand(1..3)
      open_issues  = @milestone.issues.opened
      open_issues  = open_issues.limit(close_number)

      open_issues.each do |issue|
        Issues::CloseService.new(project: @project, current_user: @project.team.users.sample).execute(issue)
      end
    end

    Timecop.return
  end

  def reopen_issues
    count  = @milestone.issues.closed.count / 3
    issues = @milestone.issues.closed.limit(rand(count) + 1)
    issues.each { |i| i.update(state: 'reopened') }
  end
end

Gitlab::Seeder.quiet do
  if project_id = ENV['PROJECT_ID']
    project = Project.find(project_id)
    seeder = Gitlab::Seeder::Burndown.new(project)
    seeder.seed!
  else
    Project.not_mass_generated.each do |project|
      seeder = Gitlab::Seeder::Burndown.new(project)
      seeder.seed!
    end
  end
end
