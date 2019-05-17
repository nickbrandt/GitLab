# frozen_string_literal: true
FactoryBot.define do
  factory :package, class: Packages::Package do
    project
    name 'my/company/app/my-app'
    version '1.0-SNAPSHOT'
    package_type 'maven'

    factory :maven_package do
      maven_metadatum

      after :build do |package|
        package.maven_metadatum.path = "#{package.name}/#{package.version}"
      end

      after :create do |package|
        create :package_file, :xml, package: package
        create :package_file, :jar, package: package
        create :package_file, :pom, package: package
      end
    end

    factory :npm_package do
      sequence(:name) { |n| "@#{project.root_namespace.path}/package-#{n}"}
      version '1.0.0'
      package_type 'npm'

      after :create do |package|
        create :package_file, :npm, package: package
      end
    end

    factory :composer_package do
      name 'ochorocho/gitlab-composer'
      version '2.0.0'
      package_type 'composer'

      after :create do |package|
        create :package_file, :composer, package: package
        create :package_file, :composer_json, package: package
      end
    end
  end

  factory :package_file, class: Packages::PackageFile do
    package

    trait(:jar) do
      file { fixture_file_upload('ee/spec/fixtures/maven/my-app-1.0-20180724.124855-1.jar') }
      file_name 'my-app-1.0-20180724.124855-1.jar'
      file_sha1 '4f0bfa298744d505383fbb57c554d4f5c12d88b3'
      file_type 'jar'
      size { 100.kilobytes }
    end

    trait(:pom) do
      file { fixture_file_upload('ee/spec/fixtures/maven/my-app-1.0-20180724.124855-1.pom') }
      file_name 'my-app-1.0-20180724.124855-1.pom'
      file_sha1 '19c975abd49e5102ca6c74a619f21e0cf0351c57'
      file_type 'pom'
      size { 200.kilobytes }
    end

    trait(:xml) do
      file { fixture_file_upload('ee/spec/fixtures/maven/maven-metadata.xml') }
      file_name 'maven-metadata.xml'
      file_sha1 '42b1bdc80de64953b6876f5a8c644f20204011b0'
      file_type 'xml'
      size { 300.kilobytes }
    end

    trait(:npm) do
      file { fixture_file_upload('ee/spec/fixtures/npm/foo-1.0.1.tgz') }
      file_name 'foo-1.0.1.tgz'
      file_sha1 'f572d396fae9206628714fb2ce00f72e94f2258f'
      file_type 'tgz'
      size { 400.kilobytes }
    end

    trait(:composer) do
      file { fixture_file_upload('ee/spec/fixtures/composer/ochorocho-gitlab-composer-2.0.0-19c3ec.tar') }
      file_name 'ochorocho-gitlab-composer-2.0.0-19c3ec.tar'
      file_sha1 'c775f1f5cc34f272e25c17b62e1932d0ca5087f8'
      file_type 'tar'
    end

    trait(:composer_json) do
      file { fixture_file_upload('ee/spec/fixtures/composer/version-2.0.0.json') }
      file_name 'version-2.0.0.json'
      file_sha1 'ce13c0eb486b7f7704a4a79694bd39b88c97f8de'
      file_type 'json'
    end

    trait :object_storage do
      file_store { Packages::PackageFileUploader::Store::REMOTE }
    end
  end

  factory :maven_metadatum, class: Packages::MavenMetadatum do
    package
    path 'my/company/app/my-app/1.0-SNAPSHOT'
    app_group 'my.company.app'
    app_name 'my-app'
    app_version '1.0-SNAPSHOT'
  end
end
