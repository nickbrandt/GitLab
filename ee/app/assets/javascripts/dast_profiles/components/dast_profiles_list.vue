<script>
import {
  GlAlert,
  GlButton,
  GlIcon,
  GlSkeletonLoader,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';

export default {
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    GlTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    profiles: {
      type: Array,
      required: true,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    profilesPerPage: {
      type: Number,
      required: true,
    },
    hasMoreProfilesToLoad: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isErrorDismissed: false,
    };
  },
  computed: {
    hasProfiles() {
      return this.profiles.length > 0;
    },
    isLoadingInitialProfiles() {
      return this.isLoading && !this.hasProfiles;
    },
    shouldShowTable() {
      return this.isLoadingInitialProfiles || this.hasProfiles || this.hasError;
    },
  },
  tableFields: [
    {
      key: 'profileName',
      class: 'gl-word-break-all',
    },
    {
      key: 'targetUrl',
      class: 'gl-word-break-all',
    },
    {
      key: 'validationStatus',
      // NOTE: hidden for now, since the site validation is still WIP and will be finished in an upcoming iteration
      // roadmap: https://gitlab.com/groups/gitlab-org/-/epics/2912#ui-configuration
      class: 'gl-display-none',
    },
    {
      key: 'actions',
    },
  ],
};
</script>
<template>
  <section>
    <div v-if="shouldShowTable">
      <gl-table
        :aria-label="s__('DastProfiles|Site Profiles')"
        :busy="isLoadingInitialProfiles"
        :fields="$options.tableFields"
        :items="profiles"
        stacked="md"
        thead-class="gl-display-none"
      >
        <template #cell(profileName)="{ value }">
          <strong>{{ value }}</strong>
        </template>

        <template #cell(validationStatus)="{ value }">
          <span>
            <gl-icon
              :size="16"
              class="gl-vertical-align-text-bottom gl-text-gray-600"
              name="information-o"
            />
            {{ value }}
          </span>
        </template>

        <template #cell(actions)>
          <!--
            NOTE: The tooltip and `disable` on the button is temporary until the edit feature has been implemented
            further details: https://gitlab.com/gitlab-org/gitlab/-/issues/222479#proposal
           -->
          <span
            v-gl-tooltip.hover
            :title="
              s__(
                'DastProfiles|Edit feature will come soon. Please create a new profile if changes needed',
              )
            "
          >
            <gl-button disabled>{{ __('Edit') }}</gl-button>
          </span>
        </template>

        <template #table-busy>
          <div v-for="i in profilesPerPage" :key="i" data-testid="loadingIndicator">
            <gl-skeleton-loader :width="1248" :height="52">
              <rect x="0" y="16" width="300" height="20" rx="4" />
              <rect x="380" y="16" width="300" height="20" rx="4" />
              <rect x="770" y="16" width="300" height="20" rx="4" />
              <rect x="1140" y="11" width="50" height="30" rx="4" />
            </gl-skeleton-loader>
          </div>
        </template>

        <template v-if="hasError && !isErrorDismissed" #bottom-row>
          <td :colspan="$options.tableFields.length">
            <gl-alert class="gl-my-4" variant="danger" :dismissible="false">
              {{
                s__(
                  'DastProfiles|Error fetching the profiles list. Please check your network connection and try again.',
                )
              }}
            </gl-alert>
          </td>
        </template>
      </gl-table>

      <p v-if="hasMoreProfilesToLoad" class="gl-display-flex gl-justify-content-center">
        <gl-button
          data-testid="loadMore"
          :loading="isLoading && !hasError"
          @click="$emit('loadMoreProfiles')"
          >{{ __('Load more') }}</gl-button
        >
      </p>
    </div>

    <p v-else class="gl-my-4">
      {{ s__('DastProfiles|No profiles created yet') }}
    </p>
  </section>
</template>
