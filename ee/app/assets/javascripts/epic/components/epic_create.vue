<script>
import { mapState, mapActions } from 'vuex';
import {
  GlDropdown,
  GlDropdownForm,
  GlFormInput,
  GlFormCheckbox,
  GlIcon,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';

import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlDropdown,
    GlDropdownForm,
    GlFormCheckbox,
    GlIcon,
    GlButton,
    GlFormInput,
  },
  directives: {
    autofocusonshow,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    alignRight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['newEpicTitle', 'newEpicConfidential', 'epicCreateInProgress']),
    buttonLabel() {
      return this.epicCreateInProgress ? __('Creating epic') : __('Create epic');
    },
    isEpicCreateDisabled() {
      return !this.newEpicTitle.length;
    },
    epicTitle: {
      set(value) {
        this.setEpicCreateTitle({
          newEpicTitle: value,
        });
      },
      get() {
        return this.newEpicTitle;
      },
    },
    epicConfidential: {
      set(value) {
        this.setEpicCreateConfidential({
          newEpicConfidential: value,
        });
      },
      get() {
        return this.newEpicConfidential;
      },
    },
  },
  methods: {
    ...mapActions(['setEpicCreateTitle', 'createEpic', 'setEpicCreateConfidential']),
  },
};
</script>

<template>
  <div class="epic-create-dropdown">
    <gl-dropdown
      :text="__('New epic')"
      :right="alignRight"
      category="primary"
      variant="success"
      data-qa-selector="new_epic_button"
      data-toggle="dropdown"
    >
      <gl-dropdown-form class="gl-p-0 gl-outline-none">
        <gl-form-input
          ref="epicTitleInput"
          v-model="epicTitle"
          v-autofocusonshow
          :disabled="epicCreateInProgress"
          :placeholder="__('Title')"
          type="text"
          class="form-control"
          data-qa-selector="epic_title_field"
          @keyup.enter.exact="createEpic"
        />
        <gl-form-checkbox
          v-model="epicConfidential"
          class="gl-my-5 gl-mr-0"
          data-qa-selector="confidential_epic_checkbox"
          ><span> {{ __('Make this epic confidential') }} </span>
          <span
            v-gl-tooltip.viewport.top.hover
            :title="
              __(
                'This epic and its child elements will only be visible to team members with at minimum Reporter access.',
              )
            "
            :aria-label="
              __(
                'This epic and its child elements will only be visible to team members with at minimum Reporter access.',
              )
            "
          >
            <gl-icon name="question" :size="12"
          /></span>
        </gl-form-checkbox>
        <gl-button
          :disabled="isEpicCreateDisabled"
          :loading="epicCreateInProgress"
          category="primary"
          variant="success"
          class="gl-mt-3 gl-w-auto! gl-xs-w-full!"
          :class="{ 'gl-hover-text-white!': !isEpicCreateDisabled }"
          data-qa-selector="create_epic_button"
          @click.stop="createEpic"
          >{{ buttonLabel }}</gl-button
        >
      </gl-dropdown-form>
    </gl-dropdown>
  </div>
</template>
