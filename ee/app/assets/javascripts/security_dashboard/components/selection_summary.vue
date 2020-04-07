<script>
import { s__, __, n__ } from '~/locale';
import { GlDeprecatedButton, GlFormSelect } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import toast from '~/vue_shared/plugins/global_toast';
import createFlash from '~/flash';

const REASON_NONE = __('[No reason]');
const REASON_WONT_FIX = __("Won't fix / Accept risk");
const REASON_FALSE_POSITIVE = __('False positive');

export default {
  name: 'SelectionSummary',
  components: {
    GlDeprecatedButton,
    GlFormSelect,
  },
  props: {
    refetchVulnerabilities: {
      type: Function,
      required: true,
    },
    selectedVulnerabilities: {
      type: Array,
      required: true,
    },
  },
  data: () => ({
    dismissalReason: null,
  }),
  computed: {
    selectedVulnerabilitiesCount() {
      return this.selectedVulnerabilities.length;
    },
    canDismissVulnerability() {
      return this.dismissalReason && this.selectedVulnerabilitiesCount > 0;
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
    handleDismiss(e) {
      if (!this.canDismissVulnerability) {
        return;
      }

      if (this.dismissalReason === REASON_NONE) {
        this.dismissSelectedVulnerabilities();
      } else {
        this.dismissSelectedVulnerabilities({ comment: this.dismissalReason });
      }
    },
    dismissSelectedVulnerabilities(e) {
      console.log(__('dismissed e: '), e);
      const promises = this.selectedVulnerabilities.map(vulnerability =>
        axios.post('/root/security-reports/-/vulnerability_feedback', {
          // TODO need vulnerability.create_vulnerability_feedback_dismissal_path
          vulnerability_feedback: {
            category: vulnerability.reportType.toLowerCase(),
            comment: this.dismissalReason,
            feedback_type: 'dismissal',
            // TODO NEED PROJECT_FINGERPRINT
            // project_fingerprint: vulnerability.project_fingerprint,
            vulnerability_data: {
              id: parseInt(vulnerability.id.split('/').slice(-1)[0], 10),
            },
          },
        }),
      );

      Promise.all(promises)
        .then(() => {
          toast(
            n__(
              '%d vulnerability dismissed',
              '%d vulnerabilities dismissed',
              this.selectedVulnerabilities.length,
            ),
          );
        })
        .catch(() => {
          createFlash(
            s__('Security Reports|There was an error dismissing the vulnerabilities.'),
            'alert',
            document.querySelector('.ci-table'),
          );
        })
        .finally(() => {
          // TODO: Make sure this works
          this.refetchVulnerabilities();
        });
    },
  },
  dismissalReasons: [
    { value: null, text: __('Select a reason') },
    REASON_FALSE_POSITIVE,
    REASON_WONT_FIX,
    REASON_NONE,
  ],
};
</script>

<template>
  <div class="card">
    <form class="card-body d-flex align-items-center" @submit.prevent="handleDismiss">
      <span>{{ message }}</span>
      <gl-form-select
        v-model="dismissalReason"
        class="mx-3 w-auto"
        :options="$options.dismissalReasons"
      />
      <gl-deprecated-button type="submit" variant="close" :disabled="!canDismissVulnerability">
        {{ __('Dismiss Selected') }}
      </gl-deprecated-button>
    </form>
  </div>
</template>
