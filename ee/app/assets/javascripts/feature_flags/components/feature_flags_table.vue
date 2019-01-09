<script>
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
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
};
</script>
<template>
  <div class="table-holder js-feature-flag-table">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10" role="columnheader">
        {{ s__('FeatureFlags|Status') }}
      </div>
      <div class="table-section section-50" role="columnheader">
        {{ s__('FeatureFlags|Feature flag') }}
      </div>
    </div>

    <template v-for="featureFlag in featureFlags">
      <div :key="featureFlag.id" class="gl-responsive-table-row" role="row">
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|Status') }}</div>
          <div class="table-mobile-content js-feature-flag-status">
            <template v-if="featureFlag.active">
              <span class="badge badge-success">{{ s__('FeatureFlags|Active') }}</span>
            </template>
            <template v-else>
              <span class="badge badge-danger">{{ s__('FeatureFlags|Inactive') }}</span>
            </template>
          </div>
        </div>

        <div class="table-section section-50" role="gridcell">
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

        <div class="table-section section-40 table-button-footer" role="gridcell">
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
