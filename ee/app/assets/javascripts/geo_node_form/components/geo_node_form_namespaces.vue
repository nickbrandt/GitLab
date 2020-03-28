<script>
import { GlIcon, GlSearchBoxByType, GlDropdown, GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { debounce } from 'underscore';
import { __, n__ } from '~/locale';
import { SELECTIVE_SYNC_NAMESPACES } from '../constants';

export default {
  name: 'GeoNodeFormNamespaces',
  components: {
    GlIcon,
    GlSearchBoxByType,
    GlDropdown,
    GlButton,
  },
  props: {
    selectedNamespaces: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      namespaceSearch: '',
    };
  },
  computed: {
    ...mapState(['synchronizationNamespaces']),
    dropdownTitle() {
      if (this.selectedNamespaces.length === 0) {
        return __('Select groups to replicate');
      }
      return n__('%d group selected', '%d groups selected', this.selectedNamespaces.length);
    },
    noSyncNamespaces() {
      return this.synchronizationNamespaces.length === 0;
    },
  },
  watch: {
    namespaceSearch: debounce(function debounceSearch() {
      this.fetchSyncNamespaces(this.namespaceSearch);
    }, 500),
  },
  methods: {
    ...mapActions(['fetchSyncNamespaces']),
    toggleNamespace(namespace) {
      const index = this.selectedNamespaces.findIndex(id => id === namespace.id);
      if (index > -1) {
        this.$emit('removeSyncOption', { key: SELECTIVE_SYNC_NAMESPACES, index });
      } else {
        this.$emit('addSyncOption', { key: SELECTIVE_SYNC_NAMESPACES, value: namespace.id });
      }
    },
    isSelected(namespace) {
      return this.selectedNamespaces.includes(namespace.id);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownTitle" @show="fetchSyncNamespaces(namespaceSearch)">
    <gl-search-box-by-type v-model="namespaceSearch" class="m-2" />
    <li v-for="namespace in synchronizationNamespaces" :key="namespace.id">
      <gl-button class="d-flex align-items-center" @click="toggleNamespace(namespace)">
        <gl-icon :class="[{ invisible: !isSelected(namespace) }]" name="mobile-issue-close" />
        <span class="ml-1">{{ namespace.name }}</span>
      </gl-button>
    </li>
    <div v-if="noSyncNamespaces" class="text-secondary p-2">{{ __('Nothing found…') }}</div>
  </gl-dropdown>
</template>
