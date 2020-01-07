<script>
import { GlIcon, GlSearchBoxByType, GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';
import { debounce } from 'underscore';
import Api from '~/api';
import createFlash from '~/flash';
import { __ } from '~/locale';

export default {
  name: 'GeoNodeFormNamespaces',
  components: {
    GlIcon,
    GlSearchBoxByType,
    GlDropdown,
    GlDropdownItem,
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
      synchronizationNamespaces: [],
    };
  },
  watch: {
    namespaceSearch: debounce(function debounceSearch() {
      this.searchNamespaces(this.namespaceSearch);
    }, 500),
  },
  methods: {
    searchNamespaces(search) {
      Api.groups(search)
        .then(res => {
          this.synchronizationNamespaces = res;
        })
        .catch(() => {
          createFlash(__("There was an error fetching the Node's Groups"));
        });
    },
    toggleNamespace(namespace) {
      const index = this.selectedNamespaces.findIndex(id => id === namespace.id);
      if (index > -1) {
        this.$emit('removeSyncOption', { key: 'namespaceIds', index });
      } else {
        this.$emit('addSyncOption', { key: 'namespaceIds', value: namespace.id });
      }
    },
    isSelected(namespace) {
      return this.selectedNamespaces.includes(namespace.id);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="__('Select groups to replicate')" @show="searchNamespaces(namespaceSearch)">
    <gl-search-box-by-type v-model="namespaceSearch" class="m-2" />
    <gl-dropdown-item
      v-for="namespace in synchronizationNamespaces"
      :key="namespace.id"
      @click.stop.prevent="toggleNamespace(namespace)"
    >
      <gl-button class="d-flex align-items-center" @click.stop.prevent="toggleNamespace(namespace)">
        <gl-icon
          :class="[{ invisible: !isSelected(namespace) }, 'mr-1']"
          name="mobile-issue-close"
        />
        <span>{{ namespace.name }}</span>
      </gl-button>
    </gl-dropdown-item>
    <div v-if="namespaceSearch && synchronizationNamespaces === 0" class="text-secondary p-2">
      {{ __('Nothing found…') }}
    </div>
  </gl-dropdown>
</template>
