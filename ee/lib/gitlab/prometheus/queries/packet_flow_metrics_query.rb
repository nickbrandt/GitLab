# frozen_string_literal: true

module Gitlab::Prometheus::Queries
  class PacketFlowMetricsQuery < BaseQuery
    def query(namespace)
      total_query = sum_by_verdict(
        increase_query(%{destination="#{namespace}"}),
        increase_query(%{source="#{namespace}"})
      )

      transform_sum_result(client_query(total_query))
    end

    private

    def sum_by_verdict(vec1, vec2)
      %{sum by(verdict) (#{vec1} or on(source,destination,verdict) #{vec2})}
    end

    def increase_query(selector)
      %{increase(hubble_flows_processed_total{#{selector}}[1w])}
    end

    # Returns the number of forwarded and dropped packets from an instant vector:
    # [
    #  {"metric"=>{"verdict"=>"FORWARDED"}, "value"=>[1582231596.64, "73772.43143284984"]},
    #  {"metric"=>{"verdict"=>"DROPPED"}, "value"=>[1582231596.64, "5.002730665588791"]}
    # ]
    def transform_sum_result(vector)
      values = vector.each_with_object({ "DROPPED" => 0, "FORWARDED" => 0 }) do |val, acc|
        acc[val["metric"].first.second] = val["value"].last.to_i
      end

      { forwards: values["FORWARDED"], drops: values["DROPPED"] }
    end
  end
end
