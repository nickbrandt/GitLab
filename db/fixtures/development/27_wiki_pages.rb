# frozen_string_literal: true

class Gitlab::Seeder::WikiPages
  attr_reader :current_user, :project

  def initialize(user, project, size)
    @current_user, @project = user, project
    @size = size.presence || 10
  end

  def seed!
    init_repo!
    pages = Array.new(num_creations).map { create_page }
    pages.sample(num_updates).each { |page| update_page(page) }
    pages.sample(num_deletions).each { |page| delete_page(page) }
  end

  def create_page
    ::WikiPages::CreateService
      .new(project, current_user, wiki_params)
      .execute
  end

  def delete_page(page)
    ::WikiPages::DestroyService.new(project, current_user).execute(page)
  end

  def update_page(page)
    params = wiki_params
    params.delete(%i[title content].sample)

    ::WikiPages::UpdateService
      .new(project, current_user, wiki_params)
      .execute(page)
  end

  def wiki_params
    {
      title: FFaker::Lorem.sentence,
      message: FFaker::Lorem.sentence,
      content: content
    }
  end

  def content
    <<~MD
    #{FFaker::Lorem.sentence}
    =========================

    #{FFaker::Lorem.paragraph}
  
    #{FFaker::Lorem.word}
    --------------------

    #{FFaker::Lorem.sentence}

    * #{FFaker::Lorem.sentence}
    * #{FFaker::Lorem.sentence}
    * #{FFaker::Lorem.sentence}
    MD
  end

  def init_repo!
    project_wiki.wiki
    return if project_wiki.has_home_page?

    params = wiki_params
    params[:title] = 'home'

    ::WikiPages::CreateService
      .new(project, current_user, params)
      .execute
  end

  def project_wiki
    @project_wiki ||= ProjectWiki.new(project, current_user)
  end

  def num_creations
    [@size, 8].max
  end

  def num_updates
    num_creations / 2
  end

  def num_deletions
    num_creations / 4
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_WIKI_PAGES'

  if ENV[flag]
    size = ENV['SEED_WIKI_PAGES_SIZE']
    admin_user = User.admins.first
    Project.visible_to_user(admin_user).first(5).each do |project|
      seeder = Gitlab::Seeder::WikiPages.new(admin_user, project, size)
      seeder.seed!
      putc '.'
    end
    puts ''
  else
    puts "Skipped. Use the `#{flag}` environment variable to seed wiki pages."
  end
rescue => e
  puts "Seeding wikis failed with #{e.message}"
  puts e.backtrace
end
