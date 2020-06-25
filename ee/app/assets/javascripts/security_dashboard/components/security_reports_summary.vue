<script>
import { GlButton, GlCard, GlCollapse, GlCollapseToggleDirective, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import AccessorUtilities from '~/lib/utils/accessor';
import { getFormattedSummary } from '../helpers';
import { COLLAPSE_SECURITY_REPORTS_SUMMARY_LOCAL_STORAGE_KEY as LOCAL_STORAGE_KEY } from '../constants';

export default {
  name: 'SecurityReportsSummary',
  components: {
    GlButton,
    GlCard,
    GlCollapse,
    GlSprintf,
  },
  directives: {
    collapseToggle: GlCollapseToggleDirective,
  },
  props: {
    summary: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isVisible: true,
    };
  },
  computed: {
    collapseButtonLabel() {
      return this.isVisible ? __('Hide details') : __('Show details');
    },
    formattedSummary() {
      return getFormattedSummary(this.summary);
    },
  },
  watch: {
    isVisible(isVisible) {
      if (!this.localStorageUsable) {
        return;
      }
      if (isVisible) {
        localStorage.removeItem(LOCAL_STORAGE_KEY);
      } else {
        localStorage.setItem(LOCAL_STORAGE_KEY, '1');
      }
    },
  },
  created() {
    this.localStorageUsable = AccessorUtilities.isLocalStorageAccessSafe();
    if (this.localStorageUsable) {
      const shouldHideSummaryDetails = Boolean(localStorage.getItem(LOCAL_STORAGE_KEY));
      this.isVisible = !shouldHideSummaryDetails;
    }
  },
};
</script>

<template>
  <gl-card body-class="gl-py-0" header-class="gl-border-b-0">
    <template #header>
      <div class="row">
        <div class="col-7">
          <strong>{{ s__('SecurityReports|Scan details') }}</strong>
        </div>
        <div v-if="localStorageUsable" class="col-5 gl-text-right">
          <gl-button
            v-collapse-toggle.security-reports-summary-details
            data-testid="collapse-button"
          >
            {{ collapseButtonLabel }}
          </gl-button>
        </div>
      </div>
    </template>
    <gl-collapse id="security-reports-summary-details" v-model="isVisible" class="gl-pb-3">
      <div v-for="[scanType, scanSummary] in formattedSummary" :key="scanType" class="row gl-my-3">
        <div class="col-6 col-md-4 col-lg-2">
          {{ scanType }}
        </div>
        <div class="col-6 col-md-8 col-lg-10">
          <gl-sprintf
            :message="
              n__('%d vulnerability', '%d vulnerabilities', scanSummary.vulnerabilitiesCount)
            "
          />
          <template v-if="scanSummary.scannedResourcesCount !== undefined">
            (<gl-sprintf
              :message="n__('%d URL scanned', '%d URLs scanned', scanSummary.scannedResourcesCount)"
            />)
          </template>
        </div>
      </div>
    </gl-collapse>
  </gl-card>
</template>
