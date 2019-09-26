<script>
// NOTE: this is a temporary component while cycle-analytics is being refactored
//        post refactor we will have a vuex store and functionality to fetch data
// https://gitlab.com/gitlab-org/gitlab/issues/32019
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';
import Api from '~/api';
import CustomStageForm from './custom_stage_form.vue';

export default {
  name: 'CustomStageFormContainer',
  components: {
    CustomStageForm,
    GlLoadingIcon,
  },
  props: {
    namespace: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      // NOTE: events will be part of the response from the new cycle analytics backend
      // https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/31535
      events: [],
      labels: [],
      isLoading: false,
    };
  },
  created() {
    this.isLoading = true;
    Api.groupLabels(this.namespace)
      .then(labels => {
        this.labels = labels.map(({ title, ...rest }) => ({ ...rest, name: title }));
      })
      .catch(() => {
        createFlash(__('There was an error fetching the form data'));
      })
      .finally(() => {
        this.isLoading = false;
      });
  },
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" size="md" class="my-3" />
  <custom-stage-form v-else :labels="labels" :events="events" />
</template>
