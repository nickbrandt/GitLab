<script>
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import DeleteFeatureFlag from './delete_feature_flag.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    DeleteFeatureFlag,
    GlButton,
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
  methods: {
    scopeTooltipText(scope) {
      return !scope.active
        ? sprintf(s__('Inactive flag for %{scope}'), { scope: scope.environment_scope })
        : '';
    },
  },
};
</script>
<template>
  <div class="table-holder js-feature-flag-table">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10" role="columnheader">
        {{ s__('FeatureFlags|Status') }}
      </div>
      <div class="table-section section-20" role="columnheader">
        {{ s__('FeatureFlags|Feature Flag') }}
      </div>
      <div class="table-section section-50" role="columnheader">
        {{ s__('FeatureFlags|Environment Specs') }}
      </div>
    </div>

    <template v-for="featureFlag in featureFlags">
      <div :key="featureFlag.id" class="gl-responsive-table-row" role="row">
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|Status') }}</div>
          <div class="table-mobile-content js-feature-flag-status">
            <span v-if="featureFlag.active" class="badge badge-success">{{
              s__('FeatureFlags|Active')
            }}</span>
            <span v-else class="badge badge-danger">{{ s__('FeatureFlags|Inactive') }}</span>
          </div>
        </div>

        <div class="table-section section-20" role="gridcell">
          <div class="table-mobile-header" role="rowheader">
            {{ s__('FeatureFlags|Feature Flag') }}
          </div>
          <div class="table-mobile-content d-flex flex-column js-feature-flag-title">
            <div class="feature-flag-name text-monospace text-truncate">{{ featureFlag.name }}</div>
            <div class="feature-flag-description text-secondary text-truncate">
              {{ featureFlag.description }}
            </div>
          </div>
        </div>

        <div class="table-section section-50" role="gridcell">
          <div class="table-mobile-header" role="rowheader">
            {{ s__('FeatureFlags|Environment Specs') }}
          </div>
          <div
            class="table-mobile-content d-flex flex-wrap justify-content-end js-feature-flag-environments"
          >
            <span
              v-for="scope in featureFlag.scopes"
              :key="scope.id"
              v-gl-tooltip.hover="scopeTooltipText(scope)"
              class="badge append-right-8 prepend-top-2"
              :class="{ 'badge-active': scope.active, 'badge-inactive': !scope.active }"
              >{{ scope.environment_scope }}</span
            >
          </div>
        </div>

        <div class="table-section section-20 table-button-footer" role="gridcell">
          <div class="table-action-buttons btn-group">
            <template v-if="featureFlag.edit_path">
              <gl-button
                v-gl-tooltip.hover.bottom="__('Edit')"
                class="js-feature-flag-edit-button"
                :href="featureFlag.edit_path"
                variant="outline-primary"
              >
                <icon name="pencil" :size="16" />
              </gl-button>
            </template>
            <template v-if="featureFlag.destroy_path">
              <delete-feature-flag
                :delete-feature-flag-url="featureFlag.destroy_path"
                :feature-flag-name="featureFlag.name"
                :modal-id="`delete-feature-flag-${featureFlag.id}`"
                :csrf-token="csrfToken"
              />
            </template>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
