<script>
import { GlLink, GlTable } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { scanners } from './constants';

export default {
  components: {
    GlLink,
    GlTable,
  },
  props: {
    // { sast: { configured: true, configuration_path: 'foo' }, dast: { ... }, ... }
    scanDetails: {
      type: Object,
      required: true,
    },
    autoDevopsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    gitlabCiPresent: {
      type: Boolean,
      required: false,
      default: false,
    },
    gitlabCiHistoryPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    scannersForDisplay() {
      return scanners.map((scanner) => {
        const scanDetail = this.scanDetails[scanner.type] ?? {};

        return {
          ...scanDetail,
          ...scanner,
        };
      });
    },
    fields() {
      const borderClasses = 'gl-border-b-1! gl-border-b-solid! gl-border-gray-100!';
      const thClass = `gl-text-gray-900 gl-bg-transparent! ${borderClasses}`;

      return [
        {
          key: 'description',
          label: s__('SecurityConfiguration|Security Control'),
          thClass,
        },
        {
          key: 'status',
          label: s__('SecurityConfiguration|Status'),
          thClass,
        },
        {
          key: 'manage',
          label: s__('SecurityConfiguration|Manage'),
          thClass,
        },
      ];
    },
  },
  methods: {
    getFeatureDocumentationLinkLabel(item) {
      return sprintf(s__('SecurityConfiguration|Feature documentation for %{featureName}'), {
        featureName: item.name,
      });
    },
  },
};
</script>

<template>
  <gl-table :items="scannersForDisplay" :fields="fields" stacked="md">
    <template #cell(description)="{ item }">
      <div class="gl-text-gray-900">{{ item.name }}</div>
      <div>
        {{ item.description }}
        <gl-link
          target="_blank"
          :href="item.helpPath"
          :aria-label="getFeatureDocumentationLinkLabel(item)"
          data-testid="docsLink"
        >
          {{ s__('SecurityConfiguration|More information') }}
        </gl-link>
      </div>
    </template>

    <template #cell(status)="{ item }">
      <component
        :is="item.statusComponent"
        :scanner="item"
        :auto-devops-enabled="autoDevopsEnabled"
        :gitlab-ci-present="gitlabCiPresent"
        :gitlab-ci-history-path="gitlabCiHistoryPath"
      />
    </template>

    <template #cell(manage)="{ item }">
      <component
        :is="item.manageComponent"
        :scanner="item"
        :auto-devops-enabled="autoDevopsEnabled"
      />
    </template>
  </gl-table>
</template>
