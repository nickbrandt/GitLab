<script>
import { GlAccordion, GlAccordionItem, GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlButton,
    GlSprintf,
  },
  inject: ['securityReportHelpPageLink'],
  props: {
    securityReportSummary: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    scansWithErrors() {
      const getScans = (reportSummary) => reportSummary?.scans || [];
      const hasErrors = (scan) => Boolean(scan.errors?.length);
      const addTitle = (scan) => ({
        ...scan,
        title: sprintf(s__('SecurityReports|%{errorName} (%{errorCount})'), {
          errorName: scan.name,
          errorCount: scan.errors.length,
        }),
      });

      return this.securityReportSummary
        ? Object.values(this.securityReportSummary)
            // generate flat array of all scans
            .flatMap(getScans)
            .filter(hasErrors)
            .map(addTitle)
        : [];
    },
    hasScansWithErrors() {
      return this.scansWithErrors.length > 0;
    },
  },
  i18n: {
    title: s__('SecurityReports|Error parsing security reports'),
    description: s__(
      'SecurityReports|The security reports below contain one or more vulnerability findings that could not be parsed and were not recorded. Download the artifacts in the job output to investigate. Ensure any security report created conforms to the relevant %{helpPageLinkStart}JSON schema%{helpPageLinkEnd}.',
    ),
  },
};
</script>

<template>
  <gl-alert v-if="hasScansWithErrors" variant="danger" :dismissible="false">
    <strong role="heading">
      {{ $options.i18n.title }}
    </strong>
    <p class="gl-mt-3">
      <gl-sprintf :message="$options.i18n.description" data-testid="description">
        <template #helpPageLink="{ content }">
          <gl-button
            variant="link"
            icon="external-link"
            :href="securityReportHelpPageLink"
            target="_blank"
          >
            {{ content }}
          </gl-button>
        </template>
      </gl-sprintf>
    </p>
    <gl-accordion :header-level="3">
      <gl-accordion-item
        v-for="{ name, errors, title } in scansWithErrors"
        :key="name"
        :title="title"
      >
        <ul class="gl-pl-4">
          <li v-for="error in errors" :key="error">{{ error }}</li>
        </ul>
      </gl-accordion-item>
    </gl-accordion>
  </gl-alert>
</template>
