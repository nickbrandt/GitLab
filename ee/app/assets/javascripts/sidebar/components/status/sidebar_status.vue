<script>
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
};
</script>

<template>
  <status :is-fetching="mediator.store.isFetching.status" :status="mediator.store.status" />
</template>
