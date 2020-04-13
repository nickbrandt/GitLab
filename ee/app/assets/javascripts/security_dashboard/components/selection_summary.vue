<script>
import { s__, n__ } from '~/locale';
import { GlNewButton, GlFormSelect } from '@gitlab/ui';
import toast from '~/vue_shared/plugins/global_toast';
import createFlash from '~/flash';
import dismissVulnerability from '../graphql/dismissVulnerability.graphql';

const REASON_NONE = s__('Security Reports|[No reason]');
const REASON_WONT_FIX = s__("Security Reports|Won't fix / Accept risk");
const REASON_FALSE_POSITIVE = s__('Security Reports|False positive');

export default {
  name: 'SelectionSummary',
  components: {
    GlNewButton,
    GlFormSelect,
  },
  props: {
    selectedVulnerabilities: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dismissalReason: null,
    };
  },
  computed: {
    selectedVulnerabilitiesCount() {
      return this.selectedVulnerabilities.length;
    },
    canDismissVulnerability() {
      return Boolean(this.dismissalReason && this.selectedVulnerabilitiesCount > 0);
    },
    message() {
      return n__(
        'Dismiss %d selected vulnerability as',
        'Dismiss %d selected vulnerabilities as',
        this.selectedVulnerabilitiesCount,
      );
    },
  },
  methods: {
    dismissalSuccessMessage() {
      return n__(
        '%d vulnerability dismissed',
        '%d vulnerabilities dismissed',
        this.selectedVulnerabilities.length,
      );
    },
    handleDismiss() {
      if (!this.canDismissVulnerability) return;

      this.dismissSelectedVulnerabilities();
    },
    dismissSelectedVulnerabilities() {
      // TODO: Batch vulnerability dismissal with https://gitlab.com/gitlab-org/gitlab/-/issues/214376
      const promises = this.selectedVulnerabilities.map(vulnerability =>
        this.$apollo.mutate({
          mutation: dismissVulnerability,
          variables: { id: vulnerability.id, comment: this.dismissalReason },
        }),
      );

      Promise.all(promises)
        .then(() => {
          toast(this.dismissalSuccessMessage());
          this.$emit('deselect-all-vulnerabilities');
          this.$emit('refetch-vulnerabilities');
        })
        .catch(() => {
          createFlash(
            s__('Security Reports|There was an error dismissing the vulnerabilities.'),
            'alert',
          );
        });
    },
  },
  dismissalReasons: [
    { value: null, text: s__('Security Reports|Select a reason') },
    REASON_FALSE_POSITIVE,
    REASON_WONT_FIX,
    REASON_NONE,
  ],
};
</script>

<template>
  <div class="card">
    <form class="card-body d-flex align-items-center" @submit.prevent="handleDismiss">
      <span ref="dismiss-message">{{ message }}</span>
      <gl-form-select
        v-model="dismissalReason"
        class="mx-3 w-auto"
        :options="$options.dismissalReasons"
      />
      <gl-new-button
        type="submit"
        class="js-no-auto-disable"
        category="secondary"
        variant="warning"
        :disabled="!canDismissVulnerability"
      >
        {{ s__('Security Reports|Dismiss Selected') }}
      </gl-new-button>
    </form>
  </div>
</template>
