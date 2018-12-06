module EE
  module StubGitlabCalls
    def stub_webide_config_file(content, sha: anything)
      allow_any_instance_of(Repository)
        .to receive(:blob_data_at).with(sha, '.gitlab/.gitlab-webide.yml')
        .and_return(content)
    end
  end
end
