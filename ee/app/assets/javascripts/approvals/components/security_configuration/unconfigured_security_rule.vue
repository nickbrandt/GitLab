<script>
import { camelCase } from 'lodash';
import { GlButton, GlLink, GlSprintf, GlSkeletonLoading } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlSkeletonLoading,
  },
  featureTypes: {
    vulnerabilityCheck: [
      'sast',
      'dast',
      'dependency_scanning',
      'secret_detection',
      'coverage_fuzzing',
    ],
    licenseCheck: ['license_scanning'],
  },
  securityRules: ['Vulnerability-Check', 'License-Check'],
  props: {
    configuration: {
      type: Object,
      required: true,
    },
    rules: {
      type: Array,
      required: true,
    },
    matchRule: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    hasApprovalRuleDefined() {
      return this.rules?.some(rule => {
        return this.matchRule.name === rule.name;
      }, this);
    },
    hasConfiguredJob() {
      const { features } = this.configuration;
      return this.$options.featureTypes[camelCase(this.matchRule.name)].some(featureType => {
        return Boolean(
          features?.some(feature => {
            return feature.type === featureType && feature.configured;
          }),
        );
      });
    },
  },
};
</script>

<template>
  <!-- 
    Excessive conditional logic is due to:

    - Can't create wrapper <div> for conditional rendering
    because parent component is a table and expects a root <tr> element

    - Can't have multiple root <tr> nodes

    - Can't create wrapper <div> since <tr> expects a <td> child element

    - Root element can't be another <template>
  -->
  <tr v-if="!hasApprovalRuleDefined || !hasConfiguredJob">
    <td v-if="isLoading" colspan="3">
      <gl-skeleton-loading :lines="3" />
    </td>

    <template v-else>
      <template v-if="hasConfiguredJob">
        <td class="js-name" colspan="4">
          <div>{{ matchRule.name }}</div>
          <div class="gl-text-gray-500">
            <gl-sprintf :message="matchRule.enableDescription">
              <template #link="{ content }">
                <gl-link :href="matchRule.docsPath" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </div>
        </td>
        <td class="gl-px-2! gl-text-right">
          <gl-button @click="$emit('enable-btn-clicked')">
            {{ s__('Enable') }}
          </gl-button>
        </td>
      </template>

      <td v-else class="js-name" colspan="3">
        <div>{{ matchRule.name }}</div>
        <div class="gl-text-gray-500">
          <gl-sprintf :message="matchRule.description">
            <template #link="{ content }">
              <gl-link :href="matchRule.docsPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </td>
    </template>
  </tr>
</template>
