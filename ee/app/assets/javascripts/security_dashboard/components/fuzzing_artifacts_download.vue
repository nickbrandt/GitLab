<script>
import { s__ } from '~/locale';
import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  translations: {
    FUZZING_ARTIFACTS: s__('SecurityReports|Fuzzing artifacts'),
  },
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    jobs: {
      type: Array,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    hasDropdown() {
      return this.jobs.length > 1;
    },
  },
  methods: {
    artifactDownloadUrl(job) {
      return `/api/v4/projects/${this.projectId}/jobs/artifacts/${job.ref}/download?job=${job.name}`;
    },
  },
};
</script>

<template>
  <div>
    <strong>{{ s__('SecurityReports|Download Report') }}</strong>
    <gl-dropdown
      v-if="hasDropdown"
      class="d-block mt-1"
      :text="$options.translations.FUZZING_ARTIFACTS"
      variant="primary"
    >
      <gl-dropdown-item v-for="job in jobs" :key="job.id" :href="artifactDownloadUrl(job)">{{
        job.name
      }}</gl-dropdown-item>
    </gl-dropdown>
    <gl-button
      v-else
      class="d-block mt-1"
      category="secondary"
      variant="info"
      :href="artifactDownloadUrl(jobs[0])"
      >{{ $options.translations.FUZZING_ARTIFACTS }}</gl-button
    >
  </div>
</template>
