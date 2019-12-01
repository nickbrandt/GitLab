<script>
import { mapState, mapActions } from 'vuex';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import { accessLevelReporter, projectsPerPage } from '../constants';
import { LAST_ACTIVITY_AT } from '../../shared/constants';

export default {
  components: {
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
  },
  data() {
    return {
      groupId: null,
    };
  },
  computed: {
    ...mapState('filters', ['groupNamespace']),
    showProjectsDropdownFilter() {
      return Boolean(this.groupId);
    },
  },
  methods: {
    ...mapActions('filters', ['setGroupNamespace', 'setProjectPath']),
    onGroupSelected({ id, full_path }) {
      this.groupId = id;
      this.setGroupNamespace(full_path);
      this.$emit('groupSelected', { groupId: id, groupNamespace: full_path });
    },
    onProjectsSelected(selectedProjects) {
      let projectNamespace = null;
      let projectId = null;

      if (selectedProjects.length) {
        projectNamespace = selectedProjects[0].path_with_namespace;
        projectId = selectedProjects[0].id;
      }

      this.setProjectPath(projectNamespace);
      this.$emit('projectSelected', {
        groupNamespace: this.groupNamespace,
        groupId: this.groupId,
        projectNamespace,
        projectId,
      });
    },
  },
  groupsQueryParams: {
    min_access_level: accessLevelReporter,
  },
  projectsQueryParams: {
    per_page: projectsPerPage,
    with_shared: false, // exclude forks
    order_by: LAST_ACTIVITY_AT,
  },
};
</script>

<template>
  <div class="dropdown-container d-flex flex-column flex-lg-row">
    <groups-dropdown-filter
      class="group-select"
      :query-params="$options.groupsQueryParams"
      @selected="onGroupSelected"
    />
    <projects-dropdown-filter
      v-if="showProjectsDropdownFilter"
      :key="groupId"
      class="project-select"
      :query-params="$options.projectsQueryParams"
      :group-id="groupId"
      @selected="onProjectsSelected"
    />
  </div>
</template>
