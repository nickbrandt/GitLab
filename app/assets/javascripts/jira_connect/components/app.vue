<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import GroupsList from './groups_list.vue';
import { __ } from '~/locale';

export default {
  name: 'JiraConnectApp',
  components: {
    GlButton,
    GlModal,
    GroupsList,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    namespacesEndpoint: {
      type: String,
      required: true,
    },
  },
  computed: {
    state() {
      return this.$root.$data.state || {};
    },
    error() {
      return this.state.error;
    },
  },
  modal: {
    cancelProps: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <div>
    <h1 class="page-title">{{ __('Linked namespaces') }}</h1>
    <gl-button v-gl-modal-directive="'add-namespace-modal'" category="primary" variant="info">{{
      __('Add namespace')
    }}</gl-button>
    <gl-modal
      modal-id="add-namespace-modal"
      :title="__('Link namespaces')"
      :action-cancel="$options.modal.cancelProps"
    >
      <groups-list :namespaces-endpoint="namespacesEndpoint" />
    </gl-modal>
  </div>
</template>
