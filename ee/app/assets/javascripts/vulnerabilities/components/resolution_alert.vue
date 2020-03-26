<script>
import { GlAlert } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  name: 'ResolutionAlert',
  components: {
    GlAlert,
  },
  props: {
    defaultBranchName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data: () => ({
    isVisible: true,
  }),
  computed: {
    resolutionTitle() {
      return this.defaultBranchName
        ? sprintf(__(`Vulnerability resolved in %{branch}`), { branch: this.defaultBranchName })
        : __('Vulnerability resolved in the default branch');
    },
  },
  methods: {
    dismiss() {
      // This isn't the best way to handle the dismissal, but it is a borig solution.
      // The next iteration of this is tracked in the below issue.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/212195
      this.isVisible = false;
    },
  },
};
</script>
<template>
  <gl-alert v-if="isVisible" :title="resolutionTitle" @dismiss="dismiss">
    {{
      __(
        'The vulnerability is no longer detected. Verify the vulnerability has been remediated before changing its status.',
      )
    }}
  </gl-alert>
</template>
