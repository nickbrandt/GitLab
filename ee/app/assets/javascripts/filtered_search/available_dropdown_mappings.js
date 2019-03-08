import DropdownUser from '~/filtered_search/dropdown_user';
import DropdownNonUser from '~/filtered_search/dropdown_non_user';
import DropdownWeight from './dropdown_weight';
import AvailableDropdownMappingsCE from '~/filtered_search/available_dropdown_mappings';

export default class AvailableDropdownMappings {
  constructor(container, baseEndpoint, groupsOnly, includeAncestorGroups, includeDescendantGroups) {
    this.container = container;
    this.baseEndpoint = baseEndpoint;
    this.groupsOnly = groupsOnly;
    this.includeAncestorGroups = includeAncestorGroups;
    this.includeDescendantGroups = includeDescendantGroups;

    this.ceAvailableMappings = new AvailableDropdownMappingsCE(
      container,
      baseEndpoint,
      groupsOnly,
      includeAncestorGroups,
      includeDescendantGroups,
    );
  }

  getAllowedMappings(supportedTokens) {
    const ceMappings = this.ceAvailableMappings.getMappings();

    ceMappings.milestone = {
      reference: null,
      gl: DropdownNonUser,
      extraArguments: {
        endpoint: this.getMilestoneEndpoint(),
        symbol: '%',
      },
      element: this.container.querySelector('#js-dropdown-milestone'),
    };

    ceMappings.approver = {
      reference: null,
      gl: DropdownUser,
      element: this.container.querySelector('#js-dropdown-approver'),
    };

    ceMappings.weight = {
      reference: null,
      gl: DropdownWeight,
      element: this.container.querySelector('#js-dropdown-weight'),
    };

    return this.ceAvailableMappings.buildMappings(supportedTokens, ceMappings);
  }

  getMilestoneEndpoint() {
    let endpoint = `${this.baseEndpoint}/milestones.json`;

    if (this.groupsOnly) {
      endpoint = `${endpoint}?only_group_milestones=true`;
    }

    return endpoint;
  }
}
