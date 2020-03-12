# frozen_string_literal: true

class SyncSeatLinkRequestWorker
  include ApplicationWorker

  feature_category :analysis

  idempotent!
  worker_has_external_dependencies!

  URI_PATH = '/api/v1/seat_links'

  RequestError = Class.new(StandardError)

  def perform(date, license_key, max_historical_user_count)
    response = Gitlab::HTTP.post(
      URI_PATH,
      base_uri: EE::SUBSCRIPTIONS_URL,
      headers: request_headers,
      body: request_body(date, license_key, max_historical_user_count)
    )

    raise RequestError, request_error_message(response) unless response.success?
  end

  private

  def request_body(date, license_key, max_historical_user_count)
    {
      date: date,
      license_key: license_key,
      max_historical_user_count: max_historical_user_count
    }.to_json
  end

  def request_headers
    { 'Content-Type' => 'application/json' }
  end

  def request_error_message(response)
    "Seat Link request failed! Code:#{response.code} Body:#{response.body}"
  end
end
