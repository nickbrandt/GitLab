<script>
import _ from 'underscore';
import { GlButton, GlBadge } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import EnvironmentsDropdown from './environments_dropdown.vue';
import { internalKeyID } from '../store/modules/helpers';

export default {
  components: {
    GlButton,
    GlBadge,
    ToggleButton,
    Icon,
    EnvironmentsDropdown,
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
    environmentsEndpoint: {
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
      'FeatureFlags|Feature Flag behavior is built up by creating a set of rules to define the status of target environments. A default wildcard rule %{codeStart}*%{codeEnd} for %{boldStart}All Environments%{boldEnd} is set, and you are able to add as many rules as you need by choosing environment specs below. You can toggle the behavior for each of your rules to set them %{boldStart}Active%{boldEnd} or %{boldStart}Inactive%{boldEnd}.',
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

    canUpdateFlag() {
      return !this.permissionsFlag || (this.scopes || []).every(scope => scope.can_update);
    },
    permissionsFlag() {
      return gon && gon.features && gon.features.featureFlagPermissions;
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
     *
     * @param {Object} scope
     * @param {Number} index
     * @param {Boolean} status
     */
    onUpdateScopeStatus(scope, status) {
      const index = this.formScopes.findIndex(el => el.id === scope.id);
      this.formScopes.splice(index, 1, Object.assign({}, scope, { active: status }));
    },
    /**
     * When the user selects or creates a new scope in the environemnts dropdoown
     * we update the selected value.
     *
     * @param {String} name
     * @param {Object} scope
     * @param {Number} index
     */
    updateScope(name, scope) {
      const index = this.formScopes.findIndex(el => el.id === scope.id);
      this.formScopes.splice(index, 1, Object.assign({}, scope, { environment_scope: name }));
    },
    /**
     * When the user clicks the toggle button in the new row,
     * we automatically add it as a new scope
     *
     * @param {Boolean} value the toggle value
     */
    onChangeNewScopeStatus(value) {
      const newScope = {
        active: value,
        environment_scope: this.newScope,
        id: _.uniqueId(internalKeyID),
      };

      if (this.permissionsFlag) {
        newScope.can_update = true;
        newScope.protected = false;
      }

      this.formScopes.push(newScope);

      this.newScope = '';
    },
    /**
     * When the user clicks the remove button we delete the scope
     *
     * If the scope has an ID, we need to add the `_destroy` flag
     * otherwise we can just remove it.
     * Backend needs the destroy flag only in the PUT request.
     *
     * @param {Number} index
     * @param {Object} scope
     */
    removeScope(scope) {
      const index = this.formScopes.findIndex(el => el.id === scope.id);
      if (_.isString(scope.id) && scope.id.indexOf(internalKeyID) !== -1) {
        this.formScopes.splice(index, 1);
      } else {
        this.formScopes.splice(index, 1, Object.assign({}, scope, { _destroy: true }));
      }
    },

    /**
     * When the user selects a value or creates a new value in the environments
     * dropdown in the creation row, we push a new entry with the selected value.
     *
     * @param {String}
     */
    createNewEnvironment(name) {
      this.formScopes.push({
        environment_scope: name,
        active: false,
        id: _.uniqueId(internalKeyID),
      });
      this.newScope = '';
    },
    /**
     * When the user clicks the submit button
     * it triggers an event with the form data
     */
    handleSubmit() {
      this.$emit('handleSubmit', {
        name: this.formName,
        description: this.formDescription,
        scopes: this.formScopes,
      });
    },

    canUpdateScope(scope) {
      return !this.permissionsFlag || scope.can_update;
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
          <input
            id="feature-flag-name"
            v-model="formName"
            :disabled="!canUpdateFlag"
            class="form-control"
          />
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
            :disabled="!canUpdateFlag"
            class="form-control"
            rows="4"
          ></textarea>
        </div>
      </div>

      <div class="row">
        <div class="form-group col-md-12">
          <h4>{{ s__('FeatureFlags|Target environments') }}</h4>
          <div v-html="$options.helpText"></div>

          <div class="js-scopes-table prepend-top-default">
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
                <div
                  class="table-mobile-content js-feature-flag-status d-flex align-items-center justify-content-start"
                >
                  <p v-if="isAllEnvironment(scope.environment_scope)" class="js-scope-all pl-3">
                    {{ $options.allEnvironments }}
                  </p>

                  <environments-dropdown
                    v-else
                    class="col-md-6"
                    :value="scope.environment_scope"
                    :endpoint="environmentsEndpoint"
                    :disabled="!canUpdateScope(scope)"
                    @selectEnvironment="env => updateScope(env, scope, index)"
                    @createClicked="env => updateScope(env, scope, index)"
                    @clearInput="updateScope('', scope, index)"
                  />

                  <gl-badge v-if="permissionsFlag && scope.protected" variant="success">{{
                    s__('FeatureFlags|Protected')
                  }}</gl-badge>
                </div>
              </div>

              <div class="table-section section-20" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-status">
                  <toggle-button
                    :value="scope.active"
                    :disabled-input="!canUpdateScope(scope)"
                    @change="status => onUpdateScopeStatus(scope, status)"
                  />
                </div>
              </div>

              <div class="table-section section-20" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Status') }}
                </div>
                <div class="table-mobile-content js-feature-flag-delete">
                  <gl-button
                    v-if="!isAllEnvironment(scope.environment_scope) && canUpdateScope(scope)"
                    class="js-delete-scope btn-transparent"
                    @click="removeScope(scope)"
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
                  <environments-dropdown
                    class="js-new-scope-name col-md-6"
                    :endpoint="environmentsEndpoint"
                    :value="newScope"
                    @selectEnvironment="env => createNewEnvironment(env)"
                    @createClicked="env => createNewEnvironment(env)"
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
