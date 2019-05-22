<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import DependencyListAlert from './dependency_list_alert.vue';

export default {
  name: 'DependencyListJobFailedAlert',
  components: {
    DependencyListAlert,
    GlButton,
  },
  props: {
    jobPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      message: sprintf(
        __(
          'The %{jobName} job has failed and cannot generate the list. Please ensure the job is running properly and run the pipeline again.',
        ),
        { jobName: '<code>dependency_list</code>' },
        false,
      ),
    };
  },
};
</script>

<template>
  <dependency-list-alert
    type="danger"
    :header-text="s__('Dependencies|Job failed to generate the dependency list')"
  >
    <p v-html="message"></p>
    <gl-button :href="jobPath" class="btn-inverted btn-danger mb-2">
      {{ __('View job') }}
    </gl-button>
  </dependency-list-alert>
</template>
