# frozen_string_literal: true

return if Rails.env.production?

require 'graphql/rake_task'

namespace :gitlab do
  OUTPUT_DIR = Rails.root.join("doc/api/graphql/reference")
  TEMPLATES_DIR = 'lib/gitlab/graphql/docs/templates/'

  # Defines tasks for dumping the GraphQL schema:
  # - gitlab:graphql:schema:dump
  # - gitlab:graphql:schema:idl
  # - gitlab:graphql:schema:json
  GraphQL::RakeTask.new(
    schema_name: 'GitlabSchema',
    dependencies: [:environment],
    directory: OUTPUT_DIR,
    idl_outfile: "gitlab_schema.graphql",
    json_outfile: "gitlab_schema.json"
  )

  namespace :graphql do
    desc 'GitLab | GraphQL | Generate GraphQL docs'
    task compile_docs: :environment do
      renderer = Gitlab::Graphql::Docs::Renderer.new(GitlabSchema.graphql_definition, render_options)

      renderer.write

      puts "Documentation compiled. Successful generated graphql docs and wrote inside #{OUTPUT_DIR}"
    end
  end
end

def render_options
  {
    output_dir: OUTPUT_DIR,
    template: Rails.root.join(TEMPLATES_DIR, 'default.md.haml')
  }
end

def format_output(str)
  heading = '#' * 10
  puts heading
  puts '#'
  puts "# #{str}"
  puts '#'
  puts heading
end
