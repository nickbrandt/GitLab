<script>
import { mapActions, mapState } from 'vuex';
import { GlAlert, GlEmptyState, GlLoadingIcon, GlModalDirective as GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import states from '../constants/show';

const commonTableClasses = ['gl-py-5', 'gl-border-b-1', 'gl-border-b-solid', 'gl-border-gray-100'];

export default {
  components: {
    GlAlert,
    GlEmptyState,
    GlLoadingIcon,
  },
  directives: {
    GlModal,
  },
  props: {
    emptyStatePath: {
      required: true,
      type: String,
    },
  },
  translations: {
    emptyStateTitle: s__('UserLists|There are no users'),
    emptyStateDescription: s__(
      'UserLists|Define a set of users to be used within feature flag strategies',
    ),
    userIdLabel: s__('UserLists|User IDs'),
    userIdColumnHeader: s__('UserLists|User ID'),
    errorMessage: __('Something went wrong on our end. Please try again!'),
  },
  classes: {
    headerClasses: [
      'gl-display-flex',
      'gl-justify-content-space-between',
      'gl-pb-5',
      'gl-border-b-1',
      'gl-border-b-solid',
      'gl-border-gray-100',
    ].join(' '),
    tableHeaderClasses: commonTableClasses.join(' '),
    tableRowClasses: [
      ...commonTableClasses,
      'gl-display-flex',
      'gl-justify-content-space-between',
      'gl-align-items-center',
    ].join(' '),
  },
  modalId: 'add-userids-modal',
  computed: {
    ...mapState(['userList', 'userIds', 'state']),
    name() {
      return this.userList?.name ?? '';
    },
    hasUserIds() {
      return this.userIds.length > 0;
    },
    isLoading() {
      return this.state === states.LOADING;
    },
    hasError() {
      return this.state === states.ERROR;
    },
  },
  mounted() {
    this.fetchUserList();
  },
  methods: {
    ...mapActions(['fetchUserList', 'dismissErrorAlert']),
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="hasError" variant="danger" @dismiss="dismissErrorAlert">
      {{ $options.translations.errorMessage }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="xl" class="mt-5" />
    <div v-else>
      <div :class="$options.classes.headerClasses">
        <div>
          <h3>{{ name }}</h3>
          <h4 class="gl-text-gray-700">{{ $options.translations.userIdLabel }}</h4>
        </div>
      </div>
      <div v-if="hasUserIds">
        <div :class="$options.classes.tableHeaderClasses">
          {{ $options.translations.userIdColumnHeader }}
        </div>
        <div
          v-for="id in userIds"
          :key="id"
          data-testid="user-id-row"
          :class="$options.classes.tableRowClasses"
        >
          <span data-testid="user-id">{{ id }}</span>
        </div>
      </div>
      <gl-empty-state
        v-else
        :title="$options.translations.emptyStateTitle"
        :description="$options.translations.emptyStateDescription"
        :svg-path="emptyStatePath"
      />
    </div>
  </div>
</template>
