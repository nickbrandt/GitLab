# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_version, class: 'Packages::Go::ModuleVersion' do
    skip_create

    initialize_with do
      p = attributes[:params]
      s = Packages::SemVer.parse(p.semver, prefixed: true)

      raise ArgumentError.new("invalid sematic version: '#{p.semver}''") if !s && p.semver

      new(p.mod, p.type, p.commit, name: p.name, semver: s, ref: p.ref)
    end

    mod { create :go_module }
    type { :commit }
    commit { raise ArgumentError.new("commit is required") }
    name { nil }
    semver { nil }
    ref { nil }

    params { OpenStruct.new(mod: mod, type: type, commit: commit, name: name, semver: semver, ref: ref) }

    trait :tagged do
      name { raise ArgumentError.new("name is required") }
      ref { mod.project.repository.find_tag(name) }
      commit { ref.dereferenced_target }

      params { OpenStruct.new(mod: mod, type: :ref, commit: commit, semver: name, ref: ref) }
    end

    trait :pseudo do
      transient do
        prefix { raise ArgumentError.new("prefix is required") }
      end

      type { :pseudo }
      name { "#{prefix}#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..11]}" }

      params { OpenStruct.new(mod: mod, type: :pseudo, commit: commit, name: name, semver: name) }
    end
  end
end
