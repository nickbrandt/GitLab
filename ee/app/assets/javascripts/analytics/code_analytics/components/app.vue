<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import FileQuantityDropdown from './file_quantity_dropdown.vue';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import { PROJECTS_PER_PAGE, DEFAULT_FILE_QUANTITY } from '../constants';
import createStore from '../store';
import { LAST_ACTIVITY_AT } from '../../shared/constants';

export default {
  name: 'CodeAnalytics',
  store: createStore(),
  components: {
    GlEmptyState,
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
    FileQuantityDropdown,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      multiProjectSelect: false,
    };
  },
  computed: {
    ...mapState(['selectedGroup', 'selectedProject', 'selectedFileQuantity']),
    displayFileQuantityFilter() {
      return this.selectedGroup && this.selectedProject;
    },
  },
  mounted() {
    this.setSelectedFileQuantity(DEFAULT_FILE_QUANTITY);
  },
  methods: {
    ...mapActions(['setSelectedGroup', 'setSelectedProject', 'setSelectedFileQuantity']),
    onGroupSelect(group) {
      this.setSelectedGroup(group);
    },
    onProjectSelect(projects) {
      const project = projects.length ? projects[0] : null;
      this.setSelectedProject(project);
    },
    onFileQuantitySelect(fileQuantity) {
      this.setSelectedFileQuantity(fileQuantity);
    },
  },
  groupsQueryParams: {
    min_access_level: featureAccessLevel.EVERYONE,
  },
  projectsQueryParams: {
    per_page: PROJECTS_PER_PAGE,
    with_shared: false,
    order_by: LAST_ACTIVITY_AT,
  },
};
</script>

<template>
  <div>
    <div class="page-title-holder d-flex align-items-center">
      <h3 class="page-title">{{ __('Code Analytics') }}</h3>
    </div>
    <div class="mw-100">
      <div
        class="mt-3 py-2 px-3 d-flex bg-gray-light border-top border-bottom flex-column flex-md-row justify-content-start"
      >
        <groups-dropdown-filter
          class="dropdown-select"
          :query-params="$options.groupsQueryParams"
          @selected="onGroupSelect"
        />
        <projects-dropdown-filter
          v-if="selectedGroup"
          :key="selectedGroup.id"
          class="ml-md-1 mt-1 mt-md-0 dropdown-select"
          :group-id="selectedGroup.id"
          :query-params="$options.projectsQueryParams"
          :multi-select="multiProjectSelect"
          @selected="onProjectSelect"
        />
        <div
          v-if="displayFileQuantityFilter"
          class="ml-0 ml-md-auto mt-2 mt-md-0 d-flex flex-column flex-md-row align-items-md-center justify-content-md-end"
        >
          <label class="text-bold mb-0 mr-2">{{ s__('CodeAnalytics|Max files') }}</label>
          <file-quantity-dropdown
            :selected="selectedFileQuantity"
            @selected="onFileQuantitySelect"
          />
        </div>
      </div>
    </div>
    <gl-empty-state
      :title="__('Identify the most frequently changed files in your repository')"
      :description="
        __(
          'Identify areas of the codebase associated with a lot of churn, which can indicate potential code hotspots.',
        )
      "
      :svg-path="emptyStateSvgPath"
    />
  </div>
</template>
