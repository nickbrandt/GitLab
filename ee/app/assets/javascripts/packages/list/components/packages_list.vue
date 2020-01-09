<script>
import { mapState } from 'vuex';
import { GlTable, GlPagination, GlButton, GlSorting, GlSortingItem, GlModal } from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import Icon from '~/vue_shared/components/icon.vue';
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
} from '../constants';
import { TrackingActions } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';

export default {
  components: {
    GlTable,
    GlPagination,
    GlSorting,
    GlSortingItem,
    GlButton,
    TimeAgoTooltip,
    GlModal,
    Icon,
  },
  mixins: [Tracking.mixin()],
  data() {
    return {
      modalId: 'confirm-delete-pacakge',
      itemToBeDeleted: null,
    };
  },
  computed: {
    ...mapState({
      list: 'packages',
      perPage: state => state.pagination.perPage,
      totalItems: state => state.pagination.total,
      page: state => state.pagination.page,
      canDestroyPackage: state => state.config.canDestroyPackage,
      isGroupPage: state => state.config.isGroupPage,
    }),
    currentPage: {
      get() {
        return this.page;
      },
      set(value) {
        this.$emit('page:changed', value);
      },
    },
    orderBy() {
      return 'name';
    },
    sort() {
      return 'asc';
    },
    //  end of vuex placeholder
    sortText() {
      const field = this.sortableFields.find(s => s.key === this.orderBy);
      return field ? field.label : '';
    },
    isSortAscending() {
      return this.sort === 'asc';
    },
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    showActions() {
      return this.canDestroyPackage;
    },
    sortableFields() {
      // This list is filtered in the case of the project page, and the project column is removed
      return [
        {
          key: LIST_KEY_NAME,
          label: LIST_LABEL_NAME,
          class: ['text-left'],
        },
        {
          key: LIST_KEY_PROJECT,
          label: LIST_LABEL_PROJECT,
          class: ['text-center'],
        },
        {
          key: LIST_KEY_VERSION,
          label: LIST_LABEL_VERSION,
          class: ['text-center'],
        },
        {
          key: LIST_KEY_PACKAGE_TYPE,
          label: LIST_LABEL_PACKAGE_TYPE,
          class: ['text-center'],
        },
        {
          key: LIST_KEY_CREATED_AT,
          label: LIST_LABEL_CREATED_AT,
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
    onDirectionChange() {
      // to be connected to the sorting api when the api is ready
    },
    onSortItemClick() {
      // to be connected to the sorting api when the api is ready
    },
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.$refs.packageListDeleteModal.show();
    },
    deleteItemConfirmation() {
      this.$emit('package:delete', this.itemToBeDeleted.id);
      this.track(TrackingActions.DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
    deleteItemCanceled() {
      // this is going to be used to support ui tracking in the future
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
        ref="packageListSorting"
        class="my-3"
        :text="sortText"
        :is-ascending="isSortAscending"
        @sortDirectionChange="onDirectionChange"
      >
        <gl-sorting-item
          v-for="item in sortableFields"
          ref="packageListSortItem"
          :key="item.key"
          @click="onSortItemClick(item.key)"
        >
          {{ item.label }}
        </gl-sorting-item>
      </gl-sorting>

      <gl-table
        ref="packageListTable"
        :items="list"
        :fields="headerFields"
        :no-local-sorting="true"
        stacked="md"
      >
        <template #name="{value}">
          <div ref="col-name" class="flex-truncate-parent">
            <a href="#" class="flex-truncate-child" data-qa-selector="package_link">
              {{ value }}
            </a>
          </div>
        </template>

        <template #project="{value}">
          <div ref="col-project" class="flex-truncate-parent">
            <a :href="value" class="flex-truncate-child"> {{ value }} </a>
          </div>
        </template>
        <template #version="{value}">
          {{ value }}
        </template>
        <template #package_type="{value}">
          {{ value }}
        </template>
        <template #created_at="{value}">
          <time-ago-tooltip :time="value" />
        </template>
        <template #actions="{item}">
          <gl-button
            ref="action-delete"
            variant="danger"
            :title="s__('PackageRegistry|Remove package')"
            :aria-label="s__('PackageRegistry|Remove package')"
            @click="setItemToBeDeleted(item)"
          >
            <icon name="remove" />
          </gl-button>
        </template>
      </gl-table>
      <gl-pagination
        ref="packageListPagination"
        v-model="currentPage"
        :per-page="perPage"
        :total-items="totalItems"
        align="center"
        class="w-100"
      />

      <gl-modal
        ref="packageListDeleteModal"
        :modal-id="modalId"
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
