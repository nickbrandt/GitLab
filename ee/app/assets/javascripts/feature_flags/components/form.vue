<script>
import _ from 'underscore';
import { GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    ToggleButton,
    Icon,
  },
  props: {
    name: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    scopes: {
      type: Array,
      required: false,
      default: () => [],
    },
    cancelPath: {
      type: String,
      required: true,
    },
    submitText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      formName: this.name,
      formDescription: this.description,
      formScopes: this.scopes || [],

      newScope: '',
    };
  },
  helpText: sprintf(
    s__(
      'FeatureFlags|Feature Flag behavior is built up by creating a set of rules to define the status of target environments. A default wildcare rule %{codeStart}*%{codeEnd} for %{boldStart}All Environments%{boldEnd} is set, and you are able to add as many rules as you need by choosing environment specs below. You can toggle the behavior for each of your rules to set them %{boldStart}Active%{boldEnd} or %{boldStart}Inactive%{boldEnd}.',
    ),
    {
      codeStart: '<code>',
      codeEnd: '</code>',
      boldStart: '<b>',
      boldEnd: '</b>',
    },
    false,
  ),
  allEnvironments: s__('FeatureFlags|* (All Environments)'),
  all: '*',
  computed: {
    filteredScopes() {
      // eslint-disable-next-line no-underscore-dangle
      return this.formScopes.filter(scope => !scope._destroy);
    },
  },
  watch: {
    newScope(newVal) {
      if (!_.isEmpty(newVal)) {
        this.addNewScope();
      }
    },
  },
  methods: {
    isAllEnvironment(name) {
      return name === this.$options.all;
    },
    /**
     * When the user updates the status of
     * an existing scope we toggle the status for
     * the `formScopes`
     */
    onUpdateScopeStatus(scope, index, status) {
      this.formScopes.splice(index, 1, Object.assign({}, scope, { active: status }));
    },
    addNewScope() {
      const uniqueId = _.uniqueId('scope_');
      this.formScopes.push({ environment_scope: this.newScope, active: false, uniqueId });

      this.$nextTick(() => {
        this.$refs[uniqueId][0].focus();

        this.newScope = '';
      });
    },
    /**
     * When the user clicks the toggle button in the new row,
     * we automatically add it as a new scope
     *
     * @param {Boolean} value the toggle value
     */
    onChangeNewScopeStatus(value) {
      this.formScopes.push({
        active: value,
        environment_scope: this.newScope,
      });

      this.newScope = '';
    },
    /**
     * When the user clicks the remove button we delete the scope
     *
     * If the scope has an ID, we need to add the `_destroy` flag
     * otherwise we can just remove it.
     * Backend needs the destroy flag only in the PUT request.
     */
    removeScope(index, scope) {
      if (scope.id) {
        this.formScopes.splice(index, 1, Object.assign({}, scope, { _destroy: true }));
      } else {
        this.formScopes.splice(index, 1);
      }
    },
    handleSubmit() {
      this.$emit('handleSubmit', {
        name: this.formName,
        description: this.formDescription,
        scopes: this.formScopes,
      });
    },
  },
};
</script>
<template>
  <form>
    <fieldset>
      <div class="row">
        <div class="form-group col-md-4">
          <label for="feature-flag-name" class="label-bold">{{ s__('FeatureFlags|Name') }}</label>
          <input id="feature-flag-name" v-model="formName" class="form-control" />
        </div>
      </div>

      <div class="row">
        <div class="form-group col-md-4">
          <label for="feature-flag-description" class="label-bold">
            {{ s__('FeatureFlags|Description') }}
          </label>
          <textarea
            id="feature-flag-description"
            v-model="formDescription"
            class="form-control"
            rows="4"
          ></textarea>
        </div>
      </div>

      <div class="row">
        <div class="form-group col-md-12">
          <h4>{{ s__('FeatureFlags|Target environments') }}</h4>
          <div v-html="$options.helpText"></div>

          <div class="js-scopes-table table-holder prepend-top-default">
            <div class="gl-responsive-table-row table-row-header" role="row">
              <div class="table-section section-60" role="columnheader">
                {{ s__('FeatureFlags|Environment Spec') }}
              </div>
              <div class="table-section section-20" role="columnheader">
                {{ s__('FeatureFlags|Status') }}
              </div>
            </div>

            <div
              v-for="(scope, index) in filteredScopes"
              :key="scope.id"
              class="gl-responsive-table-row"
              role="row"
            >
              <div class="table-section section-60" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Environment Spec') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <p v-if="isAllEnvironment(scope.environment_scope)" class="js-scope-all">
                    {{ $options.allEnvironments }}
                  </p>
                  <input
                    v-else
                    :ref="scope.uniqueId"
                    v-model="scope.environment_scope"
                    type="text"
                    class="form-control col-md-6 prepend-left-4"
                  />
                </div>
              </div>

              <div class="table-section section-20" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <toggle-button
                    :value="scope.active"
                    @change="status => onUpdateScopeStatus(scope, index, status)"
                  />
                </div>
              </div>

              <div class="table-section section-20" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-delete">
                  <gl-button
                    v-if="!isAllEnvironment(scope.environment_scope)"
                    class="js-delete-scope btn-transparent"
                    @click="removeScope(index, scope)"
                  >
                    <icon name="clear" />
                  </gl-button>
                </div>
              </div>
            </div>

            <div class="js-add-new-scope gl-responsive-table-row" role="row">
              <div class="table-section section-60" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Environment Spec') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <input
                    v-model="newScope"
                    type="text"
                    class="js-new-scope-name form-control col-md-6 prepend-left-4"
                  />
                </div>
              </div>

              <div class="table-section section-20" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <toggle-button :value="false" @change="onChangeNewScopeStatus" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </fieldset>

    <div class="form-actions">
      <gl-button
        type="button"
        variant="success"
        class="js-ff-submit col-xs-12"
        @click="handleSubmit"
        >{{ submitText }}</gl-button
      >
      <gl-button
        :href="cancelPath"
        variant="secondary"
        class="js-ff-cancel col-xs-12 float-right"
        >{{ __('Cancel') }}</gl-button
      >
    </div>
  </form>
</template>
