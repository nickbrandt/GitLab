<script>
import { GlTable, GlPagination, GlButton, GlSorting, GlSortingItem, GlModal } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { s__, sprintf } from '~/locale';

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
  props: {
    canDestroyPackage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      modalId: 'confirm-delete-pacakge',
      itemToBeDeleted: null,
    };
  },
  computed: {
    // the following computed properties are going to be connected to vuex
    list() {
      return [];
    },
    perPage() {
      return 20;
    },
    totalItems() {
      return 100;
    },
    currentPage: {
      get() {
        return 1;
      },
      set() {
        // do something with value
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
      return [
        {
          key: 'name',
          label: s__('Name'),
          tdClass: ['w-25'],
        },
        {
          key: 'version',
          label: s__('Version'),
        },
        {
          key: 'package_type',
          label: s__('Type'),
        },
        {
          key: 'created_at',
          label: s__('Created'),
        },
      ];
    },
    headerFields() {
      const actions = {
        key: 'actions',
        label: '',
        tdClass: ['text-right'],
      };
      return this.showActions ? [...this.sortableFields, actions] : this.sortableFields;
    },
    modalAction() {
      return s__('PackageRegistry|Delete Package');
    },
    deletePackageDescription() {
      if (!this.itemToBeDeleted) {
        return '';
      }
      return sprintf(
        s__(
          'PackageRegistry|You are about to delete <b>%{packageName}</b>, this operation is irreversible, are you sure?',
        ),
        { packageName: this.itemToBeDeleted.name },
        false,
      );
    },
  },
  methods: {
    onDirectionChange() {},
    onSortItemClick() {},
    setItemToBeDeleted({ name, id }) {
      this.itemToBeDeleted = { name, id };
      this.$refs.packageListDeleteModal.show();
    },
    deleteItemConfirmation() {
      // this is going to be connected to vuex action
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
      >
        <template #name="{value}">
          <div ref="col-name" class="flex-truncate-parent">
            <a href="/asd/lol" class="flex-truncate-child" data-qa-selector="package_link">
              {{ value }}
            </a>
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
