<script>
import { mapState, mapActions } from 'vuex';
import ProjectsDropdownFilter from '../../shared/components/projects_dropdown_filter.vue';
import { accessLevelReporter, projectsPerPage } from '../constants';
import { LAST_ACTIVITY_AT } from '../../shared/constants';

export default {
  components: {
    ProjectsDropdownFilter,
  },
  props: {
    group: {
      type: Object,
      required: false,
      default: null,
    },
    project: {
      type: Object,
      required: false,
      default: null,
    }
  },
  data() {
    return {
      groupId: this.group && this.group.id ? this.group.id : null,
    };
  },
  computed: {
    ...mapState('filters', ['groupNamespace']),
    showProjectsDropdownFilter() {
      return Boolean(this.groupId);
    },
    projects() {
      return this.project && Object.keys(this.project).length ? [this.project] : null;
    },
  },
  methods: {
    ...mapActions('filters', ['setGroupNamespace', 'setProjectPath']),
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
  projectsQueryParams: {
    per_page: projectsPerPage,
    with_shared: false, // exclude forks
    order_by: LAST_ACTIVITY_AT,
    include_subgroups: true,
  },
};
</script>

<template>
  <div class="dropdown-container d-flex flex-column flex-lg-row">
    <projects-dropdown-filter
      v-if="showProjectsDropdownFilter"
      :key="groupId"
      class="project-select"
      :default-projects="projects"
      :query-params="$options.projectsQueryParams"
      :group-id="groupId"
      @selected="onProjectsSelected"
    />
  </div>
</template>
