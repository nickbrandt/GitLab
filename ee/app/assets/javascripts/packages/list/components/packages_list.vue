<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlTable,
  GlPagination,
  GlButton,
  GlSorting,
  GlSortingItem,
  GlModal,
  GlLink,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  LIST_KEY_NAME,
  LIST_KEY_PROJECT,
  LIST_KEY_VERSION,
  LIST_KEY_PACKAGE_TYPE,
  LIST_KEY_CREATED_AT,
  LIST_KEY_ACTIONS,
  LIST_LABEL_NAME,
  LIST_LABEL_PROJECT,
  LIST_LABEL_VERSION,
  LIST_LABEL_PACKAGE_TYPE,
  LIST_LABEL_CREATED_AT,
  LIST_LABEL_ACTIONS,
  LIST_ORDER_BY_PACKAGE_TYPE,
  ASCENDING_ODER,
  DESCENDING_ORDER,
} from '../constants';
import { TrackingActions } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';
import PackageTags from '../../shared/components/package_tags.vue';

export default {
  components: {
    GlTable,
    GlPagination,
    GlSorting,
    GlSortingItem,
    GlButton,
    GlLink,
    TimeAgoTooltip,
    GlModal,
    GlIcon,
    PackageTags,
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
      orderBy: state => state.sorting.orderBy,
      sort: state => state.sorting.sort,
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
    sortText() {
      const field = this.sortableFields.find(s => s.orderBy === this.orderBy);
      return field ? field.label : '';
    },
    isSortAscending() {
      return this.sort === ASCENDING_ODER;
    },
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    showActions() {
      return !this.isGroupPage;
    },
    sortableFields() {
      // This list is filtered in the case of the project page, and the project column is removed
      return [
        {
          key: LIST_KEY_NAME,
          label: LIST_LABEL_NAME,
          orderBy: LIST_KEY_NAME,
          class: ['text-left'],
        },
        {
          key: LIST_KEY_PROJECT,
          label: LIST_LABEL_PROJECT,
          orderBy: LIST_KEY_PROJECT,
          class: ['text-center'],
        },
        {
          key: LIST_KEY_VERSION,
          label: LIST_LABEL_VERSION,
          orderBy: LIST_KEY_VERSION,
          class: ['text-center'],
        },
        {
          key: LIST_KEY_PACKAGE_TYPE,
          label: LIST_LABEL_PACKAGE_TYPE,
          orderBy: LIST_ORDER_BY_PACKAGE_TYPE,
          class: ['text-center'],
        },
        {
          key: LIST_KEY_CREATED_AT,
          label: LIST_LABEL_CREATED_AT,
          orderBy: LIST_KEY_CREATED_AT,
          class: this.showActions ? ['text-center'] : ['text-right'],
        },
      ].filter(f => f.key !== LIST_KEY_PROJECT || this.isGroupPage);
    },
    headerFields() {
      const actions = {
        key: LIST_KEY_ACTIONS,
        label: LIST_LABEL_ACTIONS,
        tdClass: ['text-right'],
      };
      return this.showActions ? [...this.sortableFields, actions] : this.sortableFields;
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
    ...mapActions(['setSorting']),
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ODER;
      this.setSorting({ sort });
      this.$emit('sort:changed');
    },
    onSortItemClick(item) {
      this.setSorting({ orderBy: item });
      this.$emit('sort:changed');
    },
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
  <div class="d-flex flex-column align-items-end">
    <slot v-if="isListEmpty" name="empty-state"></slot>
    <template v-else>
      <gl-sorting
        class="my-3"
        :text="sortText"
        :is-ascending="isSortAscending"
        @sortDirectionChange="onDirectionChange"
      >
        <gl-sorting-item
          v-for="item in sortableFields"
          ref="packageListSortItem"
          :key="item.key"
          @click="onSortItemClick(item.orderBy)"
        >
          {{ item.label }}
        </gl-sorting-item>
      </gl-sorting>

      <gl-table :items="list" :fields="headerFields" :no-local-sorting="true" stacked="md">
        <template #cell(name)="{value, item}">
          <div
            class="flex-truncate-parent d-flex align-items-center justify-content-end justify-content-md-start"
          >
            <gl-link
              v-gl-tooltip.hover
              :title="value"
              class="flex-truncate-child"
              :href="item._links.web_path"
              data-qa-selector="package_link"
            >
              {{ value }}
            </gl-link>
          </div>
          <package-tags
            v-if="item.tags && item.tags.length"
            class="prepend-left-8"
            :tags="item.tags"
            hide-label
            :tag-display-limit="1"
          />
        </template>

        <template #cell(project_path)="{item}">
          <div ref="col-project" class="flex-truncate-parent">
            <gl-link
              v-gl-tooltip.hover
              :title="item.projectPathName"
              :href="item.project_path"
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
