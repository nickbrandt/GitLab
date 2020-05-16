# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_commit, class: 'Commit' do
    skip_create

    transient do
      project { raise ArgumentError.new("project is required") }
      service { raise ArgumentError.new("this factory cannot be used without specifying a trait") }
      tag { nil }
      tag_message { nil }

      commit do
        r = service.execute

        raise "operation failed: #{r}" unless r[:status] == :success

        commit = project.repository.commit_by(oid: r[:result])

        if tag
          r = Tags::CreateService.new(project, project.owner).execute(tag, commit.sha, tag_message)

          raise "operation failed: #{r}" unless r[:status] == :success
        end

        commit
      end
    end

    initialize_with do
      commit
    end

    trait :files do
      transient do
        files { raise ArgumentError.new("files is required") }
        message { 'Add files' }
      end

      service do
        Files::MultiService.new(
          project,
          project.owner,
          commit_message: message,
          start_branch: project.repository.root_ref || 'master',
          branch_name: project.repository.root_ref || 'master',
          actions: files.map do |path, content|
            { action: :create, file_path: path, content: content }
          end
        )
      end
    end

    trait :package do
      transient do
        path { raise ArgumentError.new("path is required") }
        message { 'Add package' }
      end

      service do
        Files::MultiService.new(
          project,
          project.owner,
          commit_message: message,
          start_branch: project.repository.root_ref || 'master',
          branch_name: project.repository.root_ref || 'master',
          actions: [
            { action: :create, file_path: path + '/b.go', content: "package b\nfunc Bye() { println(\"Goodbye world!\") }\n" }
          ]
        )
      end
    end

    trait :module do
      transient do
        name { nil }
        message { 'Add module' }

        url do
          v = "#{::Gitlab.config.gitlab.host}/#{project.path_with_namespace}"

          if name
            v + '/' + name
          else
            v
          end
        end

        path do
          if name
            name + '/'
          else
            ''
          end
        end
      end

      service do
        Files::MultiService.new(
          project,
          project.owner,
          commit_message: message,
          start_branch: project.repository.root_ref || 'master',
          branch_name: project.repository.root_ref || 'master',
          actions: [
            { action: :create, file_path: path + 'go.mod', content: "module #{url}\n" },
            { action: :create, file_path: path + 'a.go', content: "package a\nfunc Hi() { println(\"Hello world!\") }\n" }
          ]
        )
      end
    end
  end
end
