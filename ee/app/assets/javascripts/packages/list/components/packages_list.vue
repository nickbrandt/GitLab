<script>
import { mapState, mapGetters } from 'vuex';
import { GlPagination, GlModal, GlTooltipDirective } from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import { TrackingActions } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';
import PackagesListLoader from './packages_list_loader.vue';
import PackagesListRow from './packages_list_row.vue';

export default {
  components: {
    GlPagination,
    GlModal,
    PackagesListLoader,
    PackagesListRow,
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

    <div v-else-if="isLoading">
      <packages-list-loader :is-group="isGroupPage" />
    </div>

    <template v-else>
      <div data-qa-selector="packages-table">
        <packages-list-row
          v-for="pk in list"
          :key="pk.id"
          :package-entity="pk"
          @packageToDelete="setItemToBeDeleted"
        />
      </div>

      <gl-pagination
        v-model="currentPage"
        :per-page="perPage"
        :total-items="totalItems"
        align="center"
        class="w-100 mt-2"
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
