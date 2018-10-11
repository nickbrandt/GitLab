describe QA::Git::Repository do
  let(:repository) { described_class.new }

  before do
    cd_empty_temp_directory
    set_bad_uri
    repository.use_default_credentials
  end

  describe '#clone' do
    it 'is unable to resolve host' do
      expect(repository.clone).to include("fatal: unable to access 'http://root@foo/bar.git/'")
    end
  end

  describe '#push_changes' do
    before do
      `git init` # need a repo to push from
    end

    it 'fails to push changes' do
      expect(repository.push_changes).to include("error: failed to push some refs to 'http://root@foo/bar.git'")
    end
  end

  def cd_empty_temp_directory
    tmp_dir = 'tmp/git-repository-spec/'
    FileUtils.rm_rf(tmp_dir) if ::File.exist?(tmp_dir)
    FileUtils.mkdir_p tmp_dir
    FileUtils.cd tmp_dir
  end

  def set_bad_uri
    repository.uri = 'http://foo/bar.git'
  end
end
