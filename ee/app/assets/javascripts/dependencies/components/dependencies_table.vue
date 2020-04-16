<script>
import { cloneDeep } from 'lodash';
import { GlBadge, GlIcon, GlLink, GlButton, GlSkeletonLoading, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DependenciesTableRow from './dependencies_table_row.vue';
import DependencyLicenseLinks from './dependency_license_links.vue';
import DependencyVulnerabilities from './dependency_vulnerabilities.vue';

const tdClass = (value, key, item) => {
  const classes = [];

  // Don't draw a border between a row and its `row-details` slot
  // eslint-disable-next-line no-underscore-dangle
  if (item._showDetails) {
    classes.push('border-bottom-0');
  }

  if (key === 'isVulnerable') {
    classes.push('text-right');
  }

  return classes;
};

export default {
  name: 'DependenciesTable',
  components: {
    DependenciesTableRow,
    DependencyLicenseLinks,
    DependencyVulnerabilities,
    GlBadge,
    GlIcon,
    GlLink,
    GlButton,
    GlSkeletonLoading,
    GlTable,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    dependencies: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    const tableSections = [
      { className: 'section-20', label: s__('Dependencies|Status') },
      { className: 'section-20', label: s__('Dependencies|Component') },
      { className: 'section-10', label: s__('Dependencies|Version') },
      { className: 'section-20', label: s__('Dependencies|Packager') },
      { className: 'section-15', label: s__('Dependencies|Location') },
      { className: 'section-15', label: s__('Dependencies|License') },
    ];

    return {
      localDependencies: this.transformDependenciesForUI(this.dependencies),
      tableSections,
    };
  },
  computed: {
    anyDependencyHasVulnerabilities() {
      return this.localDependencies.some(({ vulnerabilities }) => vulnerabilities.length > 0);
    },
  },
  watch: {
    dependencies(dependencies) {
      this.localDependencies = this.transformDependenciesForUI(dependencies);
    },
  },
  methods: {
    // The GlTable component mutates the `_showDetails` property on items
    // passed to it in order to track the visibilty of each row's `row-details`
    // slot. So, create a deep clone of them here to avoid mutating the
    // `dependencies` prop.
    transformDependenciesForUI(dependencies) {
      return cloneDeep(dependencies);
    },
  },
  fields: [
    { key: 'component', label: s__('Dependencies|Component'), tdClass },
    { key: 'packager', label: s__('Dependencies|Packager'), tdClass },
    { key: 'location', label: s__('Dependencies|Location'), tdClass },
    { key: 'license', label: s__('Dependencies|License'), tdClass },
    { key: 'isVulnerable', label: '', tdClass },
  ],
  DEPENDENCIES_PER_PAGE: 20,
};
</script>

<template>
  <!-- tbody- and thead-class props can be removed when
    https://gitlab.com/gitlab-org/gitlab/-/issues/213324 is fixed -->
  <gl-table
    v-if="glFeatures.dependencyListUi"
    :fields="$options.fields"
    :items="localDependencies"
    :busy="isLoading"
    details-td-class="pt-0"
    stacked="md"
    thead-class="gl-text-gray-900"
    tbody-class="gl-text-gray-900"
  >
    <!-- toggleDetails and detailsShowing are scoped slot props provided by
      GlTable; they mutate/read the item's _showDetails property, which GlTable
      uses to show/hide the row-details slot -->
    <template #cell(component)="{ item, toggleDetails, detailsShowing }">
      <gl-button
        v-if="anyDependencyHasVulnerabilities"
        class="d-none d-md-inline"
        :class="{ invisible: !item.vulnerabilities.length }"
        variant="link"
        :aria-label="s__('Dependencies|Toggle vulnerability list')"
        @click="toggleDetails"
      >
        <gl-icon
          :name="detailsShowing ? 'chevron-up' : 'chevron-down'"
          class="text-secondary-900"
        />
      </gl-button>
      <span class="bold">{{ item.name }}</span
      >&nbsp;{{ item.version }}
    </template>

    <template #cell(location)="{ item }">
      <gl-link :href="item.location.blob_path">
        <gl-icon name="doc-text" class="align-middle" />
        {{ item.location.path }}
      </gl-link>
    </template>

    <template #cell(license)="{ item }">
      <dependency-license-links :licenses="item.licenses" :title="item.name" />
    </template>

    <template #cell(isVulnerable)="{ item, toggleDetails }">
      <!-- This badge usage will be simplified by
        https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28356 -->
      <gl-badge
        v-if="item.vulnerabilities.length"
        variant="warning"
        href="#"
        class="d-inline-flex align-items-center bg-warning-100 text-warning-700 bold"
        @click.native="toggleDetails"
      >
        <gl-icon name="warning" class="text-warning-500 mr-1" />
        {{
          n__(
            'Dependencies|%d vulnerability detected',
            'Dependencies|%d vulnerabilities detected',
            item.vulnerabilities.length,
          )
        }}
      </gl-badge>
    </template>

    <template #row-details="{ item }">
      <dependency-vulnerabilities class="ml-4" :vulnerabilities="item.vulnerabilities" />
    </template>

    <template #table-busy>
      <div class="mt-2">
        <gl-skeleton-loading v-for="n in $options.DEPENDENCIES_PER_PAGE" :key="n" :lines="1" />
      </div>
    </template>
  </gl-table>

  <div v-else>
    <div class="gl-responsive-table-row table-row-header text-2 bg-secondary-50 px-2" role="row">
      <div
        v-for="(section, index) in tableSections"
        :key="index"
        class="table-section"
        :class="section.className"
        role="rowheader"
      >
        {{ section.label }}
      </div>
    </div>

    <dependencies-table-row
      v-for="(dependency, index) in dependencies"
      :key="index"
      :dependency="dependency"
      :is-loading="isLoading"
    />
  </div>
</template>
