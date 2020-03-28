<script>
import Flash from '~/flash';
import { __ } from '~/locale';
import Status from './status.vue';

export default {
  components: {
    Status,
  },
  props: {
    mediator: {
      required: true,
      type: Object,
      validator(mediatorObject) {
        return Boolean(mediatorObject.store);
      },
    },
  },
  methods: {
    handleFormSubmission(status) {
      this.mediator.updateStatus(status).catch(() => {
        Flash(__('Error occurred while updating the issue status'));
      });
    },
  },
};
</script>

<template>
  <status
    :is-editable="mediator.store.editable"
    :is-fetching="mediator.store.isFetching.status"
    :status="mediator.store.status"
    @onFormSubmit="handleFormSubmission"
  />
</template>
