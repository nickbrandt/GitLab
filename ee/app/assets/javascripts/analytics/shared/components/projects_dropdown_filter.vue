<script>
import { sprintf, n__, __ } from '~/locale';
import $ from 'jquery';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import Api from '~/api';

export default {
  name: 'ProjectsDropdownFilter',
  components: {
    Icon,
    GlLoadingIcon,
    GlButton,
  },
  props: {
    groupId: {
      type: Number,
      required: true,
    },
    multiSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: true,
      selectedProjects: [],
    };
  },
  computed: {
    selectedProjectsLabel() {
      return this.selectedProjects.length
        ? sprintf(
            n__(
              'CycleAnalytics|%{projectName}',
              'CycleAnalytics|%d projects selected',
              this.selectedProjects.length,
            ),
            { projectName: this.selectedProjects[0].name },
          )
        : this.selectedProjectsPlaceholder;
    },
    selectedProjectsPlaceholder() {
      return this.multiSelect ? __('Select projects') : __('Select a project');
    },
  },
  mounted() {
    $(this.$refs.projectsDropdown).glDropdown({
      selectable: true,
      filterable: true,
      filterRemote: true,
      fieldName: 'project_id',
      multiSelect: this.multiSelect,
      search: {
        fields: ['name'],
      },
      clicked: this.onClick.bind(this),
      data: this.fetchData.bind(this),
      renderRow: group => this.rowTemplate(group),
      text: project => project.name,
    });
  },
  methods: {
    getSelectedProjects(selectedProject, isMarking) {
      return isMarking
        ? this.selectedProjects.concat([selectedProject])
        : this.selectedProjects.filter(project => project.id !== selectedProject.id);
    },
    setSelectedProjects(selectedObj, isMarking) {
      this.selectedProjects = this.multiSelect
        ? this.getSelectedProjects(selectedObj, isMarking)
        : [selectedObj];
    },
    onClick({ selectedObj, e, isMarking }) {
      e.preventDefault();
      this.setSelectedProjects(selectedObj, isMarking);
      this.$emit('selected', this.selectedProjects);
    },
    fetchData(term, callback) {
      this.loading = true;
      return Api.groupProjects(this.groupId, term, {}, projects => {
        this.loading = false;
        callback(projects);
      });
    },
    rowTemplate(project) {
      return `
          <li>
            <a href='#' class='dropdown-menu-link'>
              ${_.escape(project.name)}
            </a>
          </li>
        `;
    },
  },
};
</script>

<template>
  <div>
    <div ref="projectsDropdown" class="dropdown dropdown-projects">
      <gl-button
        class="dropdown-menu-toggle wide shadow-none bg-white"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
      >
        {{ selectedProjectsLabel }}
        <icon name="chevron-down" />
      </gl-button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
        <div class="dropdown-title">{{ __('Projects') }}</div>
        <div class="dropdown-input">
          <input class="dropdown-input-field" type="search" :placeholder="__('Search projects')" />
          <icon name="search" class="dropdown-input-search" data-hidden="true" />
        </div>
        <div class="dropdown-content"></div>
        <gl-loading-icon class="dropdown-loading" />
      </div>
    </div>
  </div>
</template>
