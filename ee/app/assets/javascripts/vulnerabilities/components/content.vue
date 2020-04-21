<script>
import { GlSprintf } from '@gitlab/ui';

export default {
  name: 'VulnerabilityContent',
  components: {
    GlSprintf,
  },
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
    hasLocationImage() {
      return Boolean(this.finding.location.image);
    },
    hasLocationOS() {
      return Boolean(this.finding.location.operating_system);
    },
    hasLocationFile() {
      return Boolean(this.finding.location.file);
    },
    hasLocationClass() {
      return Boolean(this.finding.location.class);
    },
    hasLocationMethod() {
      return Boolean(this.finding.location.method);
    },
    hasLinks() {
      return this.finding.links.length > 0;
    },
    hasIdentifiers() {
      return this.finding.identifiers.length > 0;
    },
  },
};
</script>
<template>
  <div class="issue-details issuable-details">
    <div class="detail-page-description p-0 my-3">
      <h2 class="title">{{ vulnerability.title }}</h2>
      <div class="description">
        <div class="md">
          <h3>{{ __('Description') }}</h3>
          <p>{{ finding.description }}</p>
          <ul>
            <li>
              <gl-sprintf :message="__('Severity: %{severity}')">
                <template #severity>{{ vulnerability.severity }}</template>
              </gl-sprintf>
            </li>
            <li>
              <gl-sprintf :message="__('Confidence: %{confidence}')">
                <template #confidence>{{ vulnerability.confidence }}</template>
              </gl-sprintf>
            </li>
            <li>
              <gl-sprintf :message="__('Report Type: %{type}')">
                <template #type>{{ vulnerability.report_type }}</template>
              </gl-sprintf>
            </li>
            <li v-if="hasLocationImage">
              <gl-sprintf :message="__('Image: %{image}')">
                <template #image>{{ finding.location.image }}</template>
              </gl-sprintf>
            </li>
            <li v-if="hasLocationOS">
              <gl-sprintf :message="__('Namespace: %{namespace}')">
                <template #namespace>{{ finding.location.operating_system }}</template>
              </gl-sprintf>
            </li>
          </ul>
          <div v-if="hasLocationFile">
            <h3>{{ __('Location') }}</h3>
            <ul>
              <li>
                {{ __('File:') }}
                <a
                  target="_blank"
                  rel="noopener noreferrer"
                  href="/root/security-reports/-/blob/ef39734934c1c7b84b200292d6e34102de9a69a5/src/main/java/com/gitlab/security_products/tests/App.java#L47"
                >
                  {{ __(`${finding.location.file}`) }}
                </a>
              </li>
              <li v-if="hasLocationClass">{{ __(`Class: ${finding.location.class}`) }}</li>
              <li v-if="hasLocationMethod">
                <gl-sprintf :message="__('Method: %{method}')">
                  <template #method>
                    <code>{{ finding.location.method }}</code>
                  </template>
                </gl-sprintf>
              </li>
            </ul>
          </div>
          <div v-if="hasLinks">
            <h3>{{ __('Links') }}</h3>
            <ul>
              <li v-for="link in finding.links" :key="link.url">
                <a target="_blank" rel="noopener noreferrer" :href="link.url">{{ link.url }}</a>
              </li>
            </ul>
          </div>
          <div v-if="hasIdentifiers">
            <h3>{{ __('Identifiers') }}</h3>
            <ul>
              <li v-for="identifier in finding.identifiers" :key="identifier.name">
                <a target="_blank" rel="noopener noreferrer" :href="identifier.url">
                  {{ identifier.name }}
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
