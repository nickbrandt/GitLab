# frozen_string_literal: true

class WebHookService
  class InternalErrorResponse
    ERROR_MESSAGE = 'internal error'

    attr_reader :body, :headers, :code

    def success?
      false
    end

    def redirection?
      false
    end

    def internal_server_error?
      true
    end

    def initialize
      @headers = Gitlab::HTTP::Response::Headers.new({})
      @body = ''
      @code = ERROR_MESSAGE
    end
  end

  REQUEST_BODY_SIZE_LIMIT = 25.megabytes
  GITLAB_EVENT_HEADER = 'X-Gitlab-Event'

  attr_accessor :hook, :data, :hook_name, :request_options

  def self.hook_to_event(hook_name)
    hook_name.to_s.singularize.titleize
  end

  def initialize(hook, data, hook_name)
    @hook = hook
    @data = data
    @hook_name = hook_name.to_s
    @request_options = {
      timeout: Gitlab.config.gitlab.webhook_timeout,
      allow_local_requests: hook.allow_local_requests?
    }
  end

  def execute
    return { status: :error, message: 'Hook disabled' } unless hook.executable?

    start_time = Gitlab::Metrics::System.monotonic_time

    response = if parsed_url.userinfo.blank?
                 make_request(hook.url)
               else
                 make_request_with_auth
               end

    log_execution(
      trigger: hook_name,
      url: hook.url,
      request_data: data,
      response: response,
      execution_duration: Gitlab::Metrics::System.monotonic_time - start_time
    )

    {
      status: :success,
      http_status: response.code,
      message: response.to_s
    }
  rescue *Gitlab::HTTP::HTTP_ERRORS,
         Gitlab::Json::LimitedEncoder::LimitExceeded, URI::InvalidURIError => e
    execution_duration = Gitlab::Metrics::System.monotonic_time - start_time
    log_execution(
      trigger: hook_name,
      url: hook.url,
      request_data: data,
      response: InternalErrorResponse.new,
      execution_duration: execution_duration,
      error_message: e.to_s
    )

    Gitlab::AppLogger.error("WebHook Error after #{execution_duration.to_i.seconds}s => #{e}")

    {
      status: :error,
      message: e.to_s
    }
  end

  def async_execute
    if rate_limited?(hook)
      log_rate_limit(hook)
    else
      Gitlab::ApplicationContext.with_context(hook.application_context) do
        WebHookWorker.perform_async(hook.id, data, hook_name)
      end
    end
  end

  private

  def parsed_url
    @parsed_url ||= URI.parse(hook.url)
  end

  def make_request(url, basic_auth = false)
    Gitlab::HTTP.post(url,
      body: Gitlab::Json::LimitedEncoder.encode(data, limit: REQUEST_BODY_SIZE_LIMIT),
      headers: build_headers(hook_name),
      verify: hook.enable_ssl_verification,
      basic_auth: basic_auth,
      **request_options)
  end

  def make_request_with_auth
    post_url = hook.url.gsub("#{parsed_url.userinfo}@", '')
    basic_auth = {
      username: CGI.unescape(parsed_url.user),
      password: CGI.unescape(parsed_url.password.presence || '')
    }
    make_request(post_url, basic_auth)
  end

  def log_execution(trigger:, url:, request_data:, response:, execution_duration:, error_message: nil)
    with_non_sticky_writes_if_load_balanced do
      handle_failure(response, hook)

      WebHookLog.create(
        web_hook: hook,
        trigger: trigger,
        url: url,
        execution_duration: execution_duration,
        request_headers: build_headers(hook_name),
        request_data: request_data,
        response_headers: format_response_headers(response),
        response_body: safe_response_body(response),
        response_status: response.code,
        internal_error_message: error_message
      )
    end
  end

  def with_non_sticky_writes_if_load_balanced
    if Feature.enabled?(:load_balancing_for_web_hook_worker)
      ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes do
        yield
      end
    else
      yield
    end
  end

  def handle_failure(response, hook)
    if response.success? || response.redirection?
      hook.enable!
    elsif response.internal_server_error?
      hook.backoff!
    else
      hook.failed!
    end
  end

  def build_headers(hook_name)
    @headers ||= begin
      {
        'Content-Type' => 'application/json',
        'User-Agent' => "GitLab/#{Gitlab::VERSION}",
        GITLAB_EVENT_HEADER => self.class.hook_to_event(hook_name)
      }.tap do |hash|
        hash['X-Gitlab-Token'] = Gitlab::Utils.remove_line_breaks(hook.token) if hook.token.present?
      end
    end
  end

  # Make response headers more stylish
  # Net::HTTPHeader has downcased hash with arrays: { 'content-type' => ['text/html; charset=utf-8'] }
  # This method format response to capitalized hash with strings: { 'Content-Type' => 'text/html; charset=utf-8' }
  def format_response_headers(response)
    response.headers.each_capitalized.to_h
  end

  def safe_response_body(response)
    return '' unless response.body

    response.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end

  def rate_limited?(hook)
    return false unless Feature.enabled?(:web_hooks_rate_limit, default_enabled: :yaml)
    return false if rate_limit.nil?

    Gitlab::ApplicationRateLimiter.throttled?(
      :web_hook_calls,
      scope: [hook],
      threshold: rate_limit
    )
  end

  def rate_limit
    @rate_limit ||= hook.rate_limit
  end

  def log_rate_limit(hook)
    payload = {
      message: 'Webhook rate limit exceeded',
      hook_id: hook.id,
      hook_type: hook.type,
      hook_name: hook_name
    }

    Gitlab::AuthLogger.error(payload)

    # Also log into application log for now, so we can use this information
    # to determine suitable limits for gitlab.com
    Gitlab::AppLogger.error(payload)
  end
end
