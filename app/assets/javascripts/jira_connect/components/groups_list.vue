<script>
import { GlTabs, GlTab, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import GroupsListItem from './groups_list_item.vue';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export default {
  components: {
    GlTabs,
    GlTab,
    GlLoadingIcon,
    GlPagination,
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
      isLoading: true,
      page: 1,
      perPage: 2,
      totalItems: 0,
    };
  },
  mounted() {
    this.loadGroups();
  },

  methods: {
    loadGroups() {
      this.isLoading = true;

      axios
        .get(this.namespacesEndpoint, {
          params: {
            page: this.page,
            per_page: this.perPage,
          },
        })
        .then(response => {
          const { page, total } = parseIntPagination(normalizeHeaders(response.headers));
          this.page = page;
          this.totalItems = total;
          this.namespaces = response.data;
        })
        .catch(() => createFlash(__('There was a problem fetching groups.')))
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <gl-tabs class="fork-groups gl-px-5">
    <gl-tab :title="__('Groups and subgroups')">
      <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-3" />
      <template v-else>
        <template v-if="namespaces.length === 0">
          <div class="gl-text-center">
            <!-- TODO: Check copy -->
            <div class="h5">{{ __('No available namespaces.') }}</div>
            <p class="gl-mt-5">
              <!-- TODO: Check copy -->
              {{ __('You must have owner or maintainer permissions to link namespaces.') }}
            </p>
          </div>
        </template>
        <template v-else>
          <ul class="groups-list group-list-tree gl-list-style-none gl-pl-0">
            <groups-list-item
              v-for="namespace in namespaces"
              :key="namespace.id"
              :group="namespace"
            />
          </ul>
        </template>
      </template>
      <gl-pagination
        v-if="totalItems > perPage && namespaces.length > 0"
        v-model="page"
        :per-page="perPage"
        :total-items="totalItems"
        @input="loadGroups"
      />
    </gl-tab>
  </gl-tabs>
</template>
