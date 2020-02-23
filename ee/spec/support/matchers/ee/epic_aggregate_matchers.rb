# frozen_string_literal: true

RSpec::Matchers.define :have_direct_sum do |type, facet, state, value|
  match do |epic_node_result|
    expect(epic_node_result).not_to be_nil
    expect(epic_node_result.direct_sums).not_to be_empty

    matching = epic_node_result.direct_sums.select { |sum| sum.type == type && sum.facet == facet && sum.state == state && sum.value == value }
    expect(matching).not_to be_empty
  end

  failure_message do |epic_node_result|
    if epic_node_result.nil?
      "expected for there to be an epic node, but it is nil"
    else
      <<~FAILURE_MSG
        expected epic node with id #{epic_node_result.epic_id} to have a sum with facet '#{facet}', state '#{state}', type '#{type}' and value '#{value}'. Has #{epic_node_result.direct_sums.count} sum objects#{", none of which match" if epic_node_result.direct_sums.count > 0}.
        Sums: #{epic_node_result.direct_sums.inspect}
      FAILURE_MSG
    end
  end
end

RSpec::Matchers.define :have_aggregate do |type, facet, state, value|
  match do |epic_node_result|
    aggregate_object = epic_node_result.aggregate_object_by(facet)
    expect(aggregate_object.send(method_name(type, state))).to eq value
  end

  failure_message do |epic_node_result|
    aggregate_object = epic_node_result.aggregate_object_by(facet)
    aggregate_method = method_name(type, state)
    "Epic node with id #{epic_node_result.epic_id} called #{aggregate_method} on aggregate object of type #{aggregate_object.class.name}. Value was expected to be #{value} but was #{aggregate_object.send(aggregate_method)}."
  end

  def method_name(type, state)
    if type == ISSUE_TYPE
      return :opened_issues if state == OPENED_ISSUE_STATE

      :closed_issues
    elsif type == EPIC_TYPE
      return :opened_epics if state == OPENED_EPIC_STATE

      :closed_epics
    end
  end
end
