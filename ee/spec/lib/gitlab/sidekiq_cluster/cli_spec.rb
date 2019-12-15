# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqCluster::CLI do
  let(:cli) { described_class.new('/dev/null') }
  let(:default_options) do
    { env: 'test', directory: Dir.pwd, max_concurrency: 50, dryrun: false }
  end

  describe '#run' do
    context 'without any arguments' do
      it 'raises CommandError' do
        expect { cli.run([]) }.to raise_error(described_class::CommandError)
      end
    end

    context 'with arguments' do
      before do
        expect(cli).to receive(:write_pid)
        expect(cli).to receive(:trap_signals)
        expect(cli).to receive(:start_loop)
      end

      it 'starts the Sidekiq workers' do
        expect(Gitlab::SidekiqCluster).to receive(:start)
                                            .with([['foo']], default_options)
                                            .and_return([])

        cli.run(%w(foo))
      end

      context 'with --negate flag' do
        it 'starts Sidekiq workers for all queues in all_queues.yml except the ones in argv' do
          expect(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return(['baz'])
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([['baz']], default_options)
                                              .and_return([])

          cli.run(%w(foo -n))
        end
      end

      context 'with --max-concurrency flag' do
        it 'starts Sidekiq workers for specified queues with a max concurrency' do
          expect(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return(%w(foo bar baz))
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([%w(foo bar baz), %w(solo)], default_options.merge(max_concurrency: 2))
                                              .and_return([])

          cli.run(%w(foo,bar,baz solo -m 2))
        end
      end

      context 'queue namespace expansion' do
        it 'starts Sidekiq workers for all queues in all_queues.yml with a namespace in argv' do
          expect(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return(['cronjob:foo', 'cronjob:bar'])
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([['cronjob', 'cronjob:foo', 'cronjob:bar']], default_options)
                                              .and_return([])

          cli.run(%w(cronjob))
        end
      end
    end
  end

  describe '#write_pid' do
    context 'when a PID is specified' do
      it 'writes the PID to a file' do
        expect(Gitlab::SidekiqCluster).to receive(:write_pid).with('/dev/null')

        cli.option_parser.parse!(%w(-P /dev/null))
        cli.write_pid
      end
    end

    context 'when no PID is specified' do
      it 'does not write a PID' do
        expect(Gitlab::SidekiqCluster).not_to receive(:write_pid)

        cli.write_pid
      end
    end
  end

  describe '#wait_for_termination' do
    it 'waits for termination of all sub-processes and succeeds after 3 checks' do
      expect(Gitlab::SidekiqCluster).to receive(:any_alive?)
        .with(an_instance_of(Array)).and_return(true, true, true, false)

      expect(Gitlab::SidekiqCluster).to receive(:pids_alive)
        .with([]).and_return([])

      expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
        .with([], :KILL)

      # Check every 0.1s, for no more than 1 second total
      cli.wait_for_termination(0.1, 1)
    end

    context 'with hanging workers' do
      before do
        expect(cli).to receive(:write_pid)
        expect(cli).to receive(:trap_signals)
        expect(cli).to receive(:start_loop)
      end

      it 'hard kills workers after timeout expires' do
        worker_pids = [101, 102, 103]
        expect(Gitlab::SidekiqCluster).to receive(:start)
                                            .with([['foo']], default_options)
                                            .and_return(worker_pids)

        expect(Gitlab::SidekiqCluster).to receive(:any_alive?)
          .with(worker_pids).and_return(true).at_least(10).times

        expect(Gitlab::SidekiqCluster).to receive(:pids_alive)
          .with(worker_pids).and_return([102])

        expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
          .with([102], :KILL)

        cli.run(%w(foo))

        # Check every 0.1s, for no more than 1 second total
        cli.wait_for_termination(0.1, 1)
      end
    end
  end

  describe '#trap_signals' do
    it 'traps the termination and forwarding signals' do
      expect(Gitlab::SidekiqCluster).to receive(:trap_terminate)
      expect(Gitlab::SidekiqCluster).to receive(:trap_forward)

      cli.trap_signals
    end
  end

  describe '#start_loop' do
    it 'runs until one of the processes has been terminated' do
      allow(cli).to receive(:sleep).with(a_kind_of(Numeric))

      expect(Gitlab::SidekiqCluster).to receive(:all_alive?)
        .with(an_instance_of(Array)).and_return(false)

      expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
        .with(an_instance_of(Array), :TERM)

      cli.start_loop
    end
  end
end
