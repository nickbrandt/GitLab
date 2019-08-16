<script>
import { mapState, mapActions } from 'vuex';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import { accessLevelReporter } from '../constants';

export default {
  components: {
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
  },
  data() {
    return {
      groupId: null,
      groupsQueryParams: {
        min_access_level: accessLevelReporter,
      },
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
      this.$emit('groupSelected', full_path);
    },
    onProjectsSelected([selectedProject]) {
      const { path } = selectedProject;
      this.setProjectPath(path);
      this.$emit('projectSelected', { namespacePath: this.groupNamespace, project: path });
    },
  },
};
</script>

<template>
  <div class="dropdown-container d-flex flex-column flex-lg-row">
    <groups-dropdown-filter
      class="group-select"
      :query-params="groupsQueryParams"
      @selected="onGroupSelected"
    />
    <projects-dropdown-filter
      v-if="showProjectsDropdownFilter"
      :key="groupId"
      class="project-select"
      :group-id="groupId"
      @selected="onProjectsSelected"
    />
  </div>
</template>
