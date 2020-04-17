# frozen_string_literal: true

FactoryBot.define do
  factory :go_module, class: 'Packages::GoModule' do
    initialize_with { new(attributes[:project], attributes[:name], attributes[:path]) }
    skip_create

    project
    path { '' }
    name { "#{Settings.build_gitlab_go_url}/#{project.full_path}#{path.empty? ? '' : '/'}#{path}" }
  end
end
