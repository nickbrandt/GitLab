<script>
import { mapState, mapGetters } from 'vuex';
import {
  GlTable,
  GlPagination,
  GlButton,
  GlModal,
  GlLink,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { LIST_KEY_ACTIONS, LIST_LABEL_ACTIONS } from '../constants';
import getTableHeaders from '../utils';
import { TrackingActions } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';
import PackageTags from '../../shared/components/package_tags.vue';
import PackagesListLoader from './packages_list_loader.vue';

export default {
  components: {
    GlTable,
    GlPagination,
    GlButton,
    GlLink,
    TimeAgoTooltip,
    GlModal,
    GlIcon,
    PackageTags,
    PackagesListLoader,
  },
  directives: { GlTooltip: GlTooltipDirective },
  mixins: [Tracking.mixin()],
  data() {
    return {
      itemToBeDeleted: null,
    };
  },
  computed: {
    ...mapState({
      perPage: state => state.pagination.perPage,
      totalItems: state => state.pagination.total,
      page: state => state.pagination.page,
      isGroupPage: state => state.config.isGroupPage,
      isLoading: 'isLoading',
    }),
    ...mapGetters({ list: 'getList' }),
    currentPage: {
      get() {
        return this.page;
      },
      set(value) {
        this.$emit('page:changed', value);
      },
    },
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    showActions() {
      return !this.isGroupPage;
    },
    headerFields() {
      const fields = getTableHeaders(this.isGroupPage);

      if (this.showActions) {
        fields.push({
          key: LIST_KEY_ACTIONS,
          label: LIST_LABEL_ACTIONS,
        });
      }

      fields[fields.length - 1].class = ['text-right'];
      return fields;
    },
    modalAction() {
      return s__('PackageRegistry|Delete package');
    },
    deletePackageDescription() {
      if (!this.itemToBeDeleted) {
        return '';
      }
      return sprintf(
        s__(
          'PackageRegistry|You are about to delete <b>%{packageName}</b>, this operation is irreversible, are you sure?',
        ),
        { packageName: `${this.itemToBeDeleted.name}:${this.itemToBeDeleted.version}` },
        false,
      );
    },
    tracking() {
      const category = this.itemToBeDeleted
        ? packageTypeToTrackCategory(this.itemToBeDeleted.package_type)
        : undefined;
      return {
        category,
      };
    },
  },
  methods: {
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.track(TrackingActions.REQUEST_DELETE_PACKAGE);
      this.$refs.packageListDeleteModal.show();
    },
    deleteItemConfirmation() {
      this.$emit('package:delete', this.itemToBeDeleted);
      this.track(TrackingActions.DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
    deleteItemCanceled() {
      this.track(TrackingActions.CANCEL_DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
  },
};
</script>

<template>
  <div class="d-flex flex-column">
    <slot v-if="isListEmpty && !isLoading" name="empty-state"></slot>

    <template v-else>
      <gl-table
        :items="list"
        :fields="headerFields"
        :no-local-sorting="true"
        :busy="isLoading"
        stacked="md"
        class="package-list-table"
        data-qa-selector="packages-table"
      >
        <template #table-busy>
          <packages-list-loader :is-group="isGroupPage" />
        </template>

        <template #cell(name)="{value, item}">
          <div
            class="flex-truncate-parent d-flex align-items-center justify-content-end justify-content-md-start"
          >
            <gl-link
              v-gl-tooltip.hover
              :title="value"
              :href="item._links.web_path"
              data-qa-selector="package_link"
            >
              {{ value }}
            </gl-link>

            <package-tags
              v-if="item.tags && item.tags.length"
              class="prepend-left-8"
              :tags="item.tags"
              hide-label
              :tag-display-limit="1"
            />
          </div>
        </template>

        <template #cell(project_path)="{item}">
          <div ref="col-project" class="flex-truncate-parent">
            <gl-link
              v-gl-tooltip.hover
              :title="item.projectPathName"
              :href="`/${item.project_path}`"
              class="flex-truncate-child"
            >
              {{ item.projectPathName }}
            </gl-link>
          </div>
        </template>
        <template #cell(version)="{value}">
          {{ value }}
        </template>
        <template #cell(package_type)="{value}">
          {{ value }}
        </template>
        <template #cell(created_at)="{value}">
          <time-ago-tooltip :time="value" />
        </template>
        <template #cell(actions)="{item}">
          <!-- _links contains the urls needed to navigate to the page details and to perform a package deletion and it comes straight from the API -->
          <gl-button
            ref="action-delete"
            variant="danger"
            :title="s__('PackageRegistry|Remove package')"
            :aria-label="s__('PackageRegistry|Remove package')"
            :disabled="!item._links.delete_api_path"
            @click="setItemToBeDeleted(item)"
          >
            <gl-icon name="remove" />
          </gl-button>
        </template>
      </gl-table>
      <gl-pagination
        v-model="currentPage"
        :per-page="perPage"
        :total-items="totalItems"
        align="center"
        class="w-100"
      />

      <gl-modal
        ref="packageListDeleteModal"
        modal-id="confirm-delete-pacakge"
        ok-variant="danger"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      >
        <template v-slot:modal-title>{{ modalAction }}</template>
        <template v-slot:modal-ok>{{ modalAction }}</template>
        <p v-html="deletePackageDescription"></p>
      </gl-modal>
    </template>
  </div>
</template>
