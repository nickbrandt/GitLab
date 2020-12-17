<script>
import { GlTabs, GlTab, GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import GroupsListItem from './groups_list_item.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    GlLoadingIcon,
    GroupsListItem,
  },
  props: {
    namespacesEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      namespaces: null,
      filter: '',
    };
  },
  computed: {
    filteredNamespaces() {
      return this.namespaces.filter(n => n.name.toLowerCase().includes(this.filter.toLowerCase()));
    },
  },

  mounted() {
    this.loadGroups();
  },

  methods: {
    loadGroups() {
      axios
        .get(this.namespacesEndpoint)
        .then(response => {
          this.namespaces = response.data;
        })
        .catch(() => createFlash(__('There was a problem fetching groups.')));
    },
  },
};
</script>
<template>
  <gl-tabs class="fork-groups gl-px-5">
    <gl-tab :title="__('Groups and subgroups')">
      <gl-loading-icon v-if="!namespaces" size="md" class="gl-mt-3" />
      <template v-else-if="namespaces.length === 0">
        <div class="gl-text-center">
          <div class="h5">{{ __('No available groups to fork the project.') }}</div>
          <p class="gl-mt-5">
            {{ __('You must have permission to create a project in a group before forking.') }}
          </p>
        </div>
      </template>
      <ul v-else class="groups-list group-list-tree gl-list-style-none gl-pl-0">
        <groups-list-item
          v-for="namespace in filteredNamespaces"
          :key="namespace.id"
          :group="namespace"
        />
      </ul>
    </gl-tab>
  </gl-tabs>
</template>
