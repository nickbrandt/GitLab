<script>
import {
  GlFormGroup,
  GlFormInput,
  GlFormCheckboxTree,
  GlButton,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import createSegmentMutation from '../graphql/mutations/create_segment.mutation.graphql';
import { DEVOPS_ADOPTION_STRINGS } from '../constants';

export default {
  name: 'DevopsAdoptionApp',
  components: {
    GlButton,
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlFormCheckboxTree,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    groups: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  i18n: DEVOPS_ADOPTION_STRINGS.modal,
  data() {
    // Get group Ids and store somewhere (Looking for the other backend issue here to see how to get group ids: https://gitlab.com/groups/gitlab-org/-/epics/4169)
    // Get existing segments in the adoption app and pass down to (table and) modal.
    // Rename this file to modal!
    return {
      name: '',
      checkboxValues: [],
    };
  },
  computed: {
    isCreateDisabled() {
      return false;
    },
    checkboxOptions() {
      return this.groups.map(({ id, full_name }) => ({ label: full_name, value: id }));
    },
  },
  methods: {
    createSegment() {
      this.$apollo.mutate({
        mutation: createSegmentMutation,
        variables: {
          name: this.name,
          groupIds: this.checkboxValues,
        },
      });
    },
  },
};
</script>
<template>
  <div>
    <gl-button v-gl-modal.createSegmentModal class="gl-mt-2" :disabled="isCreateDisabled">
      {{ $options.i18n.createSegmentButton }}
    </gl-button>
    <gl-modal
      modal-id="createSegmentModal"
      :hide-toggle-all="true"
      :title="$options.i18n.title"
      :ok-title="$options.i18n.button"
      ok-variant="info"
      @ok="createSegment"
    >
      <gl-form-group>
        <gl-form-input
          v-model="name"
          type="text"
          :placeholder="$options.i18n.namePlaceholder"
          :required="true"
        />
        <gl-form-checkbox-tree v-model="checkboxValues" :options="checkboxOptions" />
      </gl-form-group>
    </gl-modal>
  </div>
</template>
