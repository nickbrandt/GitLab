# frozen_string_literal: true

FactoryBot.define do
  factory :dependency, class: Hash do
    name { 'nokogiri' }
    packager { 'Ruby (Bundler)' }
    version { '1.8.0' }
    licenses { [] }
    location do
      {
        blob_path: '/some_project/path/Gemfile.lock',
        path:      'Gemfile.lock'
      }
    end

    trait :with_vulnerabilities do
      vulnerabilities do
        [{
           name:     'DDoS',
           severity: 'high'
         },
         {
           name:     'XSS vulnerability',
           severity: 'low'
         }]
      end
    end

    trait :with_licenses do
      licenses do
        [{
           name: 'MIT',
           url: 'http://opensource.org/licenses/mit-license'
         }]
      end
    end

    initialize_with { attributes }
  end
end
