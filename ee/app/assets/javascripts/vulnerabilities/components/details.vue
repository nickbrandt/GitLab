<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import SafeLink from 'ee/vue_shared/components/safe_link.vue';
import DetailItem from './detail_item.vue';

export default {
  name: 'VulnerabilityDetails',
  components: { GlLink, SeverityBadge, DetailItem, SafeLink, GlSprintf },
  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
    finding: {
      type: Object,
      required: true,
    },
  },
  computed: {
    location() {
      return this.finding.location || {};
    },
    scanner() {
      return this.finding.scanner || {};
    },
    fileText() {
      return (this.location.file || '') + (this.lineNumber ? `:${this.lineNumber}` : '');
    },
    fileUrl() {
      return (this.location.blob_path || '') + (this.lineNumber ? `#L${this.lineNumber}` : '');
    },
    lineNumber() {
      const { start_line: start, end_line: end } = this.location;
      return end > start ? `${start}-${end}` : start;
    },
    scannerUrl() {
      return this.scanner.url || '';
    },
  },
};
</script>

<template>
  <div class="md">
    <h1 class="mt-3 mb-2 border-bottom-0" data-testid="title">{{ vulnerability.title }}</h1>
    <h3 class="mt-0">{{ __('Description') }}</h3>
    <p data-testid="description">{{ finding.description }}</p>

    <ul>
      <detail-item :sprintf-message="__('%{labelStart}Severity:%{labelEnd} %{severity}')">
        <severity-badge :severity="vulnerability.severity" class="gl-display-inline ml-1" />
      </detail-item>
      <detail-item
        v-if="finding.evidence"
        :sprintf-message="__('%{labelStart}Evidence:%{labelEnd} %{evidence}')"
        >{{ finding.evidence }}
      </detail-item>
      <detail-item :sprintf-message="__('%{labelStart}Report Type:%{labelEnd} %{reportType}')"
        >{{ vulnerability.report_type }}
      </detail-item>
      <detail-item
        v-if="scanner.name"
        :sprintf-message="__('%{labelStart}Scanner:%{labelEnd} %{scanner}')"
      >
        <safe-link
          :href="scannerUrl"
          target="_blank"
          rel="noopener noreferrer"
          data-testid="scannerSafeLink"
        >
          <gl-sprintf
            v-if="scanner.version"
            :message="s__('Vulnerability|%{scannerName} (version %{scannerVersion})')"
          >
            <template #scannerName>{{ scanner.name }}</template>
            <template #scannerVersion>{{ scanner.version }}</template>
          </gl-sprintf>
          <template v-else>{{ scanner.name }}</template>
        </safe-link>
      </detail-item>
      <detail-item
        v-if="location.image"
        :sprintf-message="__('%{labelStart}Image:%{labelEnd} %{image}')"
        >{{ location.image }}
      </detail-item>
      <detail-item
        v-if="location.operating_system"
        :sprintf-message="__('%{labelStart}Namespace:%{labelEnd} %{namespace}')"
        >{{ location.operating_system }}
      </detail-item>
    </ul>

    <template v-if="location.file">
      <h3>{{ __('Location') }}</h3>
      <ul>
        <detail-item :sprintf-message="__('%{labelStart}File:%{labelEnd} %{file}')">
          <gl-link :href="fileUrl" target="_blank">{{ fileText }}</gl-link>
        </detail-item>
        <detail-item
          v-if="location.class"
          :sprintf-message="__('%{labelStart}Class:%{labelEnd} %{class}')"
          >{{ location.class }}
        </detail-item>
        <detail-item
          v-if="location.method"
          :sprintf-message="__('%{labelStart}Method:%{labelEnd} %{method}')"
        >
          <code>{{ location.method }}</code>
        </detail-item>
      </ul>
    </template>

    <template v-if="finding.links && finding.links.length">
      <h3>{{ __('Links') }}</h3>
      <ul>
        <li v-for="link in finding.links" :key="link.url">
          <gl-link
            :href="link.url"
            data-testid="link"
            target="_blank"
            :aria-label="__('Third Party Advisory Link')"
            :title="link.url"
          >
            {{ link.url }}
          </gl-link>
        </li>
      </ul>
    </template>

    <template v-if="finding.identifiers && finding.identifiers.length">
      <h3>{{ __('Identifiers') }}</h3>
      <ul>
        <li v-for="identifier in finding.identifiers" :key="identifier.url">
          <gl-link :href="identifier.url" data-testid="identifier" target="_blank">
            {{ identifier.name }}
          </gl-link>
        </li>
      </ul>
    </template>
  </div>
</template>
