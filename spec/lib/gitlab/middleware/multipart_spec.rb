# frozen_string_literal: true

require 'spec_helper'

require 'tempfile'

describe Gitlab::Middleware::Multipart do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:original_filename) { 'filename' }

  shared_examples_for 'multipart upload files' do
    it 'opens top-level files' do
      Tempfile.open('top-level') do |tempfile|
        rewritten = { 'file' => tempfile.path }
        in_params = { 'file.name' => original_filename, 'file.path' => tempfile.path, 'file.remote_id' => remote_id }
        env = post_env(rewritten, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect_uploaded_file(tempfile, %w(file))

        middleware.call(env)
      end
    end

    it 'opens files one level deep' do
      Tempfile.open('one-level') do |tempfile|
        in_params = { 'user' => { 'avatar' => { '.name' => original_filename, '.path' => tempfile.path, '.remote_id' => remote_id } } }
        rewritten = { 'user[avatar]' => tempfile.path }
        env = post_env(rewritten, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect_uploaded_file(tempfile, %w(user avatar))

        middleware.call(env)
      end
    end

    it 'opens files two levels deep' do
      Tempfile.open('two-levels') do |tempfile|
        in_params = { 'project' => { 'milestone' => { 'themesong' => { '.name' => original_filename, '.path' => tempfile.path, '.remote_id' => remote_id } } } }
        rewritten = { 'project[milestone][themesong]' => tempfile.path }
        env = post_env(rewritten, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect_uploaded_file(tempfile, %w(project milestone themesong))

        middleware.call(env)
      end
    end

    def expect_uploaded_file(tempfile, path, remote: false)
      expect(app).to receive(:call) do |env|
        file = get_params(env).dig(*path)
        expect(file).to be_a(::UploadedFile)
        expect(file.path).to eq(tempfile.path)
        expect(file.original_filename).to eq(original_filename)
        expect(file.remote_id).to eq(remote_id)
      end
    end
  end

  it 'rejects headers signed with the wrong secret' do
    env = post_env({ 'file' => '/var/empty/nonesuch' }, {}, 'x' * 32, 'gitlab-workhorse')

    expect { middleware.call(env) }.to raise_error(JWT::VerificationError)
  end

  it 'rejects headers signed with the wrong issuer' do
    env = post_env({ 'file' => '/var/empty/nonesuch' }, {}, Gitlab::Workhorse.secret, 'acme-inc')

    expect { middleware.call(env) }.to raise_error(JWT::InvalidIssuerError)
  end

  context 'with remote file' do
    let(:remote_id) { 'someid' }

    it_behaves_like 'multipart upload files'
  end

  context 'with local file' do
    let(:remote_id) { nil }

    it_behaves_like 'multipart upload files'
  end

  it 'allows files in uploads/tmp directory' do
    Dir.mktmpdir do |dir|
      uploads_dir = File.join(dir, 'public/uploads/tmp')
      FileUtils.mkdir_p(uploads_dir)

      allow(Rails).to receive(:root).and_return(dir)
      allow(Dir).to receive(:tmpdir).and_return(File.join(Dir.tmpdir, 'tmpsubdir'))

      Tempfile.open('top-level', uploads_dir) do |tempfile|
        env = post_env({ 'file' => tempfile.path }, { 'file.name' => original_filename, 'file.path' => tempfile.path }, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect(app).to receive(:call) do |env|
          expect(get_params(env)['file']).to be_a(::UploadedFile)
        end

        middleware.call(env)
      end
    end
  end

  context 'with packages storage' do
    let(:storage_path) { 'shared/packages' }

    RSpec.shared_examples 'allowing the upload' do
      it 'allows files to be uploaded' do
        Dir.mktmpdir do |dir|
          packages_upload_dir = File.join(dir, storage_path, 'tmp/uploads')
          FileUtils.mkdir_p(packages_upload_dir)

          Tempfile.open('top-level', packages_upload_dir) do |tempfile|
            env = post_env({ 'file' => tempfile.path }, { 'file.name' => original_filename, 'file.path' => tempfile.path }, Gitlab::Workhorse.secret, 'gitlab-workhorse')

            expect(app).to receive(:call) do |env|
              expect(get_params(env)['file']).to be_a(::UploadedFile)
            end

            middleware.call(env)
          end
        end
      end
    end

    context 'with object storage disabled' do
      before do
        stub_config(packages: {
          enabled: true,
          object_store: {
            enabled: false
          },
          storage_path: storage_path
        })
      end

      it_behaves_like 'allowing the upload' do
        before do
          expect(Gitlab.config.packages).to receive(:storage_path).and_return(storage_path)
        end
      end
    end

    context 'with object storage enabled' do
      context 'with direct upload enabled' do
        before do
          stub_config(packages: {
            enabled: true,
            object_store: {
              enabled: true,
              direct_upload: true
            }
          })
        end

        it_behaves_like 'allowing the upload' do
          before do
            expect(Gitlab.config.packages).not_to receive(:storage_path)
          end
        end
      end

      context 'with direct upload disabled' do
        before do
          stub_config(packages: {
            enabled: true,
            object_store: {
              enabled: true,
              direct_upload: false
            },
            storage_path: storage_path
          })
        end

        it_behaves_like 'allowing the upload' do
          before do
            expect(Gitlab.config.packages).to receive(:storage_path).and_return(storage_path)
          end
        end
      end
    end
  end

  it 'allows symlinks for uploads dir' do
    Tempfile.open('two-levels') do |tempfile|
      symlinked_dir = '/some/dir/uploads'
      symlinked_path = File.join(symlinked_dir, File.basename(tempfile.path))
      env = post_env({ 'file' => symlinked_path }, { 'file.name' => original_filename, 'file.path' => symlinked_path }, Gitlab::Workhorse.secret, 'gitlab-workhorse')

      allow(FileUploader).to receive(:root).and_return(symlinked_dir)
      allow(UploadedFile).to receive(:allowed_paths).and_return([symlinked_dir, Gitlab.config.uploads.storage_path])
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with(symlinked_dir).and_return(Dir.tmpdir)
      allow(File).to receive(:realpath).with(symlinked_path).and_return(tempfile.path)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(symlinked_dir).and_return(true)

      # override Dir.tmpdir because this dir is in the list of allowed paths
      # and it would match FileUploader.root path (which in this test is linked
      # to /tmp too)
      allow(Dir).to receive(:tmpdir).and_return(File.join(Dir.tmpdir, 'tmpsubdir'))

      expect(app).to receive(:call) do |env|
        expect(get_params(env)['file']).to be_a(::UploadedFile)
      end

      middleware.call(env)
    end
  end

  # Rails 5 doesn't combine the GET/POST parameters in
  # ActionDispatch::HTTP::Parameters if action_dispatch.request.parameters is set:
  # https://github.com/rails/rails/blob/aea6423f013ca48f7704c70deadf2cd6ac7d70a1/actionpack/lib/action_dispatch/http/parameters.rb#L41
  def get_params(env)
    req = ActionDispatch::Request.new(env)
    req.GET.merge(req.POST)
  end

  def post_env(rewritten_fields, params, secret, issuer)
    token = JWT.encode({ 'iss' => issuer, 'rewritten_fields' => rewritten_fields }, secret, 'HS256')
    Rack::MockRequest.env_for(
      '/',
      method: 'post',
      params: params,
      described_class::RACK_ENV_KEY => token
    )
  end
end
