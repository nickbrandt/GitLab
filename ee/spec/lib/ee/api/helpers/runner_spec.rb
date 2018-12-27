require 'spec_helper'

describe EE::API::Helpers::Runner do
  let(:helper_class) do
    Class.new do
      include API::Helpers::Runner
    end
  end

  let(:helper) { helper_class.new }

  before do
    allow(helper).to receive(:env).and_return({})
    allow(helper).to receive(:not_found!).and_raise('not found')
  end

  describe '#authenticate_job' do
    let(:build) { create(:ci_build, :running) }

    it 'handles sticking of a build when a build ID is specified' do
      allow(helper).to receive(:params).and_return(
        id: build.id, token: build.token)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .to receive(:stick_or_unstick)
        .with({}, :build, build.id)

      helper.authenticate_job!
    end

    it 'does not handle sticking if no build ID was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .not_to receive(:stick_or_unstick)

      expect { helper.authenticate_job! }.to raise_error /not found/
    end

    it 'returns the build if one could be found' do
      allow(helper).to receive(:params).and_return(
        id: build.id, token: build.token)

      expect(helper.authenticate_job!).to eq(build)
    end
  end

  describe '#current_runner' do
    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'handles sticking of a runner if a token is specified' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .to receive(:stick_or_unstick)
        .with({}, :runner, runner.token)

      helper.current_runner
    end

    it 'does not handle sticking if no token was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .not_to receive(:stick_or_unstick)

      helper.current_runner
    end

    it 'returns the runner if one could be found' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(helper.current_runner).to eq(runner)
    end
  end
end
