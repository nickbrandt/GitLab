<script>
import { escape } from 'lodash';
import { GlDeprecatedButton, GlTooltipDirective, GlModal, GlToggle, GlIcon } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ROLLOUT_STRATEGY_PERCENT_ROLLOUT, NEW_VERSION_FLAG } from '../constants';

export default {
  components: {
    GlDeprecatedButton,
    GlIcon,
    GlModal,
    GlToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    csrfToken: {
      type: String,
      required: true,
    },
    featureFlags: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      deleteFeatureFlagUrl: null,
      deleteFeatureFlagName: null,
    };
  },
  translations: {
    legacyFlagAlert: s__('FeatureFlags|Flag becomes read only soon'),
  },
  computed: {
    permissions() {
      return this.glFeatures.featureFlagPermissions;
    },
    isNewVersionFlagsEnabled() {
      return this.glFeatures.featureFlagsNewVersion;
    },
    modalTitle() {
      return sprintf(
        s__('FeatureFlags|Delete %{name}?'),
        {
          name: escape(this.deleteFeatureFlagName),
        },
        false,
      );
    },
    deleteModalMessage() {
      return sprintf(
        s__('FeatureFlags|Feature flag %{name} will be removed. Are you sure?'),
        {
          name: escape(this.deleteFeatureFlagName),
        },
        false,
      );
    },
    modalId() {
      return 'delete-feature-flag';
    },
  },
  methods: {
    isLegacyFlag(flag) {
      return this.isNewVersionFlagsEnabled && flag.version !== NEW_VERSION_FLAG;
    },
    scopeTooltipText(scope) {
      return !scope.active
        ? sprintf(s__('FeatureFlags|Inactive flag for %{scope}'), {
            scope: scope.environmentScope,
          })
        : '';
    },
    badgeText(scope) {
      const displayName =
        scope.environmentScope === '*'
          ? s__('FeatureFlags|* (All environments)')
          : scope.environmentScope;

      const displayPercentage =
        scope.rolloutStrategy === ROLLOUT_STRATEGY_PERCENT_ROLLOUT
          ? `: ${scope.rolloutPercentage}%`
          : '';

      return `${displayName}${displayPercentage}`;
    },
    featureFlagIidText(featureFlag) {
      return featureFlag.iid ? `^${featureFlag.iid}` : '';
    },
    canDeleteFlag(flag) {
      return !this.permissions || (flag.scopes || []).every(scope => scope.can_update);
    },
    setDeleteModalData(featureFlag) {
      this.deleteFeatureFlagUrl = featureFlag.destroy_path;
      this.deleteFeatureFlagName = featureFlag.name;

      this.$refs[this.modalId].show();
    },
    onSubmit() {
      this.$refs.form.submit();
    },
    toggleFeatureFlag(flag) {
      this.$emit('toggle-flag', {
        ...flag,
        active: !flag.active,
      });
    },
  },
};
</script>
<template>
  <div class="table-holder js-feature-flag-table">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10">
        {{ s__('FeatureFlags|ID') }}
      </div>
      <div class="table-section section-10" role="columnheader">
        {{ s__('FeatureFlags|Status') }}
      </div>
      <div class="table-section section-20" role="columnheader">
        {{ s__('FeatureFlags|Feature Flag') }}
      </div>
      <div class="table-section section-40" role="columnheader">
        {{ s__('FeatureFlags|Environment Specs') }}
      </div>
    </div>

    <template v-for="featureFlag in featureFlags">
      <div :key="featureFlag.id" class="gl-responsive-table-row" role="row">
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|ID') }}</div>
          <div class="table-mobile-content js-feature-flag-id">
            {{ featureFlagIidText(featureFlag) }}
          </div>
        </div>
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|Status') }}</div>
          <div class="table-mobile-content js-feature-flag-status">
            <gl-toggle
              v-if="featureFlag.update_path"
              :value="featureFlag.active"
              @change="toggleFeatureFlag(featureFlag)"
            />
            <span v-else-if="featureFlag.active" class="badge badge-success">
              {{ s__('FeatureFlags|Active') }}
            </span>
            <span v-else class="badge badge-danger">{{ s__('FeatureFlags|Inactive') }}</span>
          </div>
        </div>

        <div class="table-section section-20" role="gridcell">
          <div class="table-mobile-header" role="rowheader">
            {{ s__('FeatureFlags|Feature Flag') }}
          </div>
          <div class="table-mobile-content d-flex flex-column js-feature-flag-title">
            <div class="gl-display-flex gl-align-items-center">
              <div class="feature-flag-name text-monospace text-truncate">
                {{ featureFlag.name }}
              </div>
              <gl-icon
                v-if="isLegacyFlag(featureFlag)"
                v-gl-tooltip.hover="$options.translations.legacyFlagAlert"
                class="gl-ml-3"
                name="information-o"
              />
            </div>
            <div class="feature-flag-description text-secondary text-truncate">
              {{ featureFlag.description }}
            </div>
          </div>
        </div>

        <div class="table-section section-40" role="gridcell">
          <div class="table-mobile-header" role="rowheader">
            {{ s__('FeatureFlags|Environment Specs') }}
          </div>
          <div
            class="table-mobile-content d-flex flex-wrap justify-content-end justify-content-md-start js-feature-flag-environments"
          >
            <span
              v-for="scope in featureFlag.scopes"
              :key="scope.id"
              v-gl-tooltip.hover="scopeTooltipText(scope)"
              class="badge append-right-8 prepend-top-2"
              :class="{
                'badge-active': scope.active,
                'badge-inactive': !scope.active,
              }"
              >{{ badgeText(scope) }}</span
            >
          </div>
        </div>

        <div class="table-section section-20 table-button-footer" role="gridcell">
          <div class="table-action-buttons btn-group">
            <template v-if="featureFlag.edit_path">
              <gl-deprecated-button
                v-gl-tooltip.hover.bottom="__('Edit')"
                class="js-feature-flag-edit-button"
                variant="outline-primary"
                :href="featureFlag.edit_path"
              >
                <gl-icon name="pencil" :size="16" />
              </gl-deprecated-button>
            </template>
            <template v-if="featureFlag.destroy_path">
              <gl-deprecated-button
                v-gl-tooltip.hover.bottom="__('Delete')"
                class="js-feature-flag-delete-button"
                variant="danger"
                :disabled="!canDeleteFlag(featureFlag)"
                @click="setDeleteModalData(featureFlag)"
              >
                <gl-icon name="remove" :size="16" />
              </gl-deprecated-button>
            </template>
          </div>
        </div>
      </div>
    </template>

    <gl-modal
      :ref="modalId"
      :title="modalTitle"
      :ok-title="s__('FeatureFlags|Delete feature flag')"
      :modal-id="modalId"
      title-tag="h4"
      ok-variant="danger"
      @ok="onSubmit"
    >
      {{ deleteModalMessage }}
      <form ref="form" :action="deleteFeatureFlagUrl" method="post" class="js-requires-input">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
