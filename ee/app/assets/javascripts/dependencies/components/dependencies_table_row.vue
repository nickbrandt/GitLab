<script>
import { GlButton, GlSkeletonLoading } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import DependencyVulnerability from './dependency_vulnerability.vue';
import { MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY } from './constants';

export default {
  name: 'DependenciesTableRow',
  components: {
    DependencyVulnerability,
    GlButton,
    GlSkeletonLoading,
    Icon,
  },
  inject: {
    dependencyListVulnerabilities: {
      from: 'dependencyListVulnerabilities',
      default: false,
    },
  },
  props: {
    dependency: {
      type: Object,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isExpanded: false,
    };
  },
  computed: {
    toggleArrowName() {
      return this.isExpanded ? 'arrow-up' : 'arrow-down';
    },
    vulnerabilities() {
      const { vulnerabilities = [] } = this.dependency || {};
      return vulnerabilities;
    },
    isVulnerable() {
      return this.vulnerabilities.length > 0;
    },
    renderableVulnerabilities() {
      return this.vulnerabilities.slice(0, MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY);
    },
    vulnerabilitiesNotShown() {
      return Math.max(
        0,
        this.vulnerabilities.length - MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY,
      );
    },
  },
  watch: {
    dependency: 'collapseVulnerabilities',
    isLoading: 'collapseVulnerabilities',
  },
  methods: {
    toggleVulnerabilities() {
      this.isExpanded = !this.isExpanded;
    },
    collapseVulnerabilities() {
      this.isExpanded = false;
    },
  },
};
</script>

<template>
  <div
    v-if="dependencyListVulnerabilities"
    class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2"
  >
    <gl-skeleton-loading
      v-if="isLoading"
      :lines="1"
      class="d-flex flex-column justify-content-center h-auto"
    />
    <div v-else class="d-md-flex align-items-baseline">
      <div class="table-section section-15 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Status') }}</div>
        <div class="table-mobile-content">
          <gl-button
            v-if="isVulnerable"
            class="bold text-warning-700 text-1 text-decoration-none js-vulnerabilities-toggle"
            variant="link"
            @click="toggleVulnerabilities"
          >
            <icon :name="toggleArrowName" class="align-top text-secondary-700 d-none d-md-inline" />
            {{
              n__(
                'Dependencies|%d vulnerability',
                'Dependencies|%d vulnerabilities',
                vulnerabilities.length,
              )
            }}
          </gl-button>
          <span v-else class="text-success-500 text-1">
            <icon name="check-circle" class="align-middle mr-1" />{{ s__('Dependencies|Safe') }}
          </span>
        </div>
      </div>

      <div class="table-section section-20 section-wrap">
        <div class="table-mobile-header" role="rowheader">
          {{ s__('Dependencies|Component') }}
        </div>
        <div class="table-mobile-content">{{ dependency.name }}</div>
      </div>

      <div class="table-section section-15">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Version') }}</div>
        <div class="table-mobile-content">{{ dependency.version }}</div>
      </div>

      <div class="table-section section-20 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Packager') }}</div>
        <div class="table-mobile-content">{{ dependency.packager }}</div>
      </div>

      <div class="table-section flex-grow-1 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Location') }}</div>
        <div class="table-mobile-content">
          <a :href="dependency.location.blob_path">{{ dependency.location.path }}</a>
        </div>
      </div>
    </div>

    <ul v-if="isExpanded" class="d-none d-md-block list-unstyled mb-1">
      <li v-for="vulnerability in renderableVulnerabilities" :key="vulnerability.id">
        <dependency-vulnerability :vulnerability="vulnerability" class="mt-3" />
      </li>
      <li v-if="vulnerabilitiesNotShown" class="text-muted text-center mt-3 js-excess-message">
        {{
          n__(
            'Dependencies|%d additional vulnerability not shown',
            'Dependencies|%d additional vulnerabilities not shown',
            vulnerabilitiesNotShown,
          )
        }}
      </li>
    </ul>
  </div>

  <div v-else class="gl-responsive-table-row p-2">
    <gl-skeleton-loading
      v-if="isLoading"
      :lines="1"
      class="d-flex flex-column justify-content-center"
    />
    <template v-else>
      <div class="table-section section-20 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Component') }}</div>
        <div class="table-mobile-content">{{ dependency.name }}</div>
      </div>

      <div class="table-section section-15">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Version') }}</div>
        <div class="table-mobile-content">{{ dependency.version }}</div>
      </div>

      <div class="table-section section-20 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Packager') }}</div>
        <div class="table-mobile-content">{{ dependency.packager }}</div>
      </div>

      <div class="table-section flex-grow-1 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Location') }}</div>
        <div class="table-mobile-content">
          <a :href="dependency.location.blob_path">{{ dependency.location.path }}</a>
        </div>
      </div>
    </template>
  </div>
</template>
