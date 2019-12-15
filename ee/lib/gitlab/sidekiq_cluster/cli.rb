# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'time'

module Gitlab
  module SidekiqCluster
    class CLI
      # How often to check for processes when terminating
      CHECK_TERMINATE_INTERVAL_SECONDS = 1
      # How long to wait in total when asking for a clean termination
      # Sidekiq default to self-terminate is 25s
      TERMINATE_TIMEOUT_SECONDS = 30

      CommandError = Class.new(StandardError)

      def initialize(log_output = STDERR)
        # As recommended by https://github.com/mperham/sidekiq/wiki/Advanced-Options#concurrency
        @max_concurrency = 50
        @environment = ENV['RAILS_ENV'] || 'development'
        @pid = nil
        @interval = 5
        @alive = true
        @processes = []
        @logger = Logger.new(log_output)
        @rails_path = Dir.pwd
        @dryrun = false

        # Use a log format similar to Sidekiq to make parsing/grepping easier.
        @logger.formatter = proc do |level, date, program, message|
          "#{date.utc.iso8601(3)} #{Process.pid} TID-#{Thread.current.object_id.to_s(36)} #{level}: #{message}\n"
        end
      end

      def run(argv = ARGV)
        if argv.empty?
          raise CommandError,
            'You must specify at least one queue to start a worker for'
        end

        option_parser.parse!(argv)

        queue_groups = SidekiqCluster.parse_queues(argv)

        all_queues = SidekiqConfig.worker_queues(@rails_path)

        queue_groups.map! do |queues|
          SidekiqConfig.expand_queues(queues, all_queues)
        end

        if @negate_queues
          queue_groups.map! { |queues| all_queues - queues }
        end

        @logger.info("Starting cluster with #{queue_groups.length} processes")

        @processes = SidekiqCluster.start(queue_groups, env: @environment, directory: @rails_path,
          max_concurrency: @max_concurrency, dryrun: @dryrun)

        return if @dryrun

        write_pid
        trap_signals
        start_loop
      end

      def write_pid
        SidekiqCluster.write_pid(@pid) if @pid
      end

      def wait_for_termination(check_interval = CHECK_TERMINATE_INTERVAL_SECONDS, terminate_timeout = TERMINATE_TIMEOUT_SECONDS)
        deadline = Gitlab::Metrics::System.monotonic_time + terminate_timeout
        sleep(check_interval) while SidekiqCluster.any_alive?(@processes) && Gitlab::Metrics::System.monotonic_time < deadline

        # Hard-stop any that remain; they're likely stuck
        SidekiqCluster.signal_processes(SidekiqCluster.pids_alive(@processes), :KILL)
      end

      def trap_signals
        SidekiqCluster.trap_terminate do |signal|
          @alive = false
          SidekiqCluster.signal_processes(@processes, signal)
          wait_for_termination
        end

        SidekiqCluster.trap_forward do |signal|
          SidekiqCluster.signal_processes(@processes, signal)
        end
      end

      def start_loop
        while @alive
          sleep(@interval)

          unless SidekiqCluster.all_alive?(@processes)
            # If a child process died we'll just terminate the whole cluster. It's up to
            # runit and such to then restart the cluster.
            @logger.info('A worker terminated, shutting down the cluster')

            SidekiqCluster.signal_processes(@processes, :TERM)
            break
          end
        end
      end

      def option_parser
        OptionParser.new do |opt|
          opt.banner = "#{File.basename(__FILE__)} [QUEUE,QUEUE] [QUEUE] ... [OPTIONS]"

          opt.separator "\nOptions:\n"

          opt.on('-h', '--help', 'Shows this help message') do
            abort opt.to_s
          end

          opt.on('-m', '--max-concurrency INT', 'Maximum threads to use with Sidekiq (default: 50, 0 to disable)') do |int|
            @max_concurrency = int.to_i
          end

          opt.on('-e', '--environment ENV', 'The application environment') do |env|
            @environment = env
          end

          opt.on('-P', '--pidfile PATH', 'Path to the PID file') do |pid|
            @pid = pid
          end

          opt.on('-r', '--require PATH', 'Location of the Rails application') do |path|
            @rails_path = path
          end

          opt.on('-n', '--negate', 'Run workers for all queues in sidekiq_queues.yml except the given ones') do
            @negate_queues = true
          end

          opt.on('-i', '--interval INT', 'The number of seconds to wait between worker checks') do |int|
            @interval = int.to_i
          end

          opt.on('-d', '--dryrun', 'Print commands that would be run without this flag, and quit') do |int|
            @dryrun = true
          end
        end
      end
    end
  end
end
