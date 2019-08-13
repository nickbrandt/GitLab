<script>
// NOTE: this is a temporary component while cycle-analytics is being refactored
//        post refactor we will have a vuex store and functionality to fetch data
// https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/15039
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import CustomStageForm from './custom_stage_form.vue';

function fetchGroupLabels(groupId, query = {}) {
  const { api_version: apiVersion } = window.gon;
  const url = `/api/${apiVersion}/groups/${groupId}/labels`;
  return axios.get(url, { ...query }).then(response => response.data);
}

export default {
  name: 'CustomStageFormContainer',
  components: {
    CustomStageForm,
  },
  props: {
    groupId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      labels: [],
    };
  },
  created() {
    fetchGroupLabels(this.groupId)
      .then(labels => {
        this.labels = labels;
      })
      .catch(() => {
        createFlash(__('There was an error fetching the form data'));
      });
  },
};
</script>
<template>
  <custom-stage-form :labels="labels" />
</template>
