# frozen_string_literal: true

RSpec::Matchers.define :have_immediate_total do |type, facet, state, expected_value|
  match do |epic_node_result|
    expect(epic_node_result).not_to be_nil
    immediate_totals = epic_node_result.immediate_totals(facet)
    expect(immediate_totals).not_to be_empty

    matching = immediate_totals.select { |sum| sum.type == type && sum.facet == facet && sum.state == state && sum.value == expected_value }
    expect(matching).not_to be_empty
  end

  failure_message do |epic_node_result|
    if epic_node_result.nil?
      "expected for there to be an epic node, but it is nil"
    else
      immediate_totals = epic_node_result.immediate_totals(facet)
      <<~FAILURE_MSG
        expected epic node with id #{epic_node_result.epic_id} to have a sum with facet '#{facet}', state '#{state}', type '#{type}' and value '#{expected_value}'. Has #{immediate_totals.count} immediate sum objects#{", none of which match" if immediate_totals.count > 0}.
        Sums: #{immediate_totals.inspect}
      FAILURE_MSG
    end
  end
end

RSpec::Matchers.define :have_aggregate do |tree, type, facet, state, expected_value|
  match do |epic_node_result|
    aggregate_object = epic_node_result.public_send(:"aggregate_#{facet}", tree)
    expect(aggregate_object.public_send(method_name(type, state))).to eq expected_value
  end

  failure_message do |epic_node_result|
    aggregate_object = epic_node_result.public_send(:"aggregate_#{facet}", tree)
    aggregate_method = method_name(type, state)
    "Epic node with id #{epic_node_result.epic_id} called #{aggregate_method} on aggregate object. Value was expected to be #{expected_value} but was #{aggregate_object.send(aggregate_method)}."
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
