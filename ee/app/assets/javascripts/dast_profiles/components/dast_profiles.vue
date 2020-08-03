<script>
import * as Sentry from '@sentry/browser';
import { GlButton, GlTab, GlTabs } from '@gitlab/ui';
import ProfilesList from './dast_profiles_list.vue';
import dastSiteProfilesQuery from '../graphql/dast_site_profiles.query.graphql';

export default {
  components: {
    GlButton,
    GlTab,
    GlTabs,
    ProfilesList,
  },
  props: {
    newDastSiteProfilePath: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      siteProfiles: [],
      siteProfilesPageInfo: {},
      hasSiteProfilesLoadingError: false,
    };
  },
  apollo: {
    siteProfiles: {
      query: dastSiteProfilesQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          first: this.$options.profilesPerPage,
        };
      },
      result({ data, error }) {
        if (!error) {
          this.siteProfilesPageInfo = data.project.siteProfiles.pageInfo;
        }
      },
      update(data) {
        const siteProfileEdges = data?.project?.siteProfiles?.edges ?? [];

        return siteProfileEdges.map(({ node }) => node);
      },
      error(e) {
        this.handleLoadingError(e);
      },
    },
  },
  computed: {
    hasMoreSiteProfiles() {
      return this.siteProfilesPageInfo.hasNextPage;
    },
    isLoadingSiteProfiles() {
      return this.$apollo.queries.siteProfiles.loading;
    },
  },
  methods: {
    handleLoadingError(e) {
      Sentry.captureException(e);
      this.hasSiteProfilesLoadingError = true;
    },
    fetchMoreProfiles() {
      const { $apollo, siteProfilesPageInfo } = this;

      this.hasSiteProfilesLoadingError = false;

      $apollo.queries.siteProfiles
        .fetchMore({
          variables: { after: siteProfilesPageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            const newResult = { ...fetchMoreResult };
            const previousEdges = previousResult.project.siteProfiles.edges;
            const newEdges = newResult.project.siteProfiles.edges;

            newResult.project.siteProfiles.edges = [...previousEdges, ...newEdges];

            return newResult;
          },
        })
        .catch(e => {
          this.handleLoadingError(e);
        });
    },
  },
  profilesPerPage: 10,
};
</script>

<template>
  <section>
    <header>
      <div class="gl-display-flex gl-align-items-center gl-pt-6 gl-pb-4">
        <h2 class="my-0">
          {{ s__('DastProfiles|Manage Profiles') }}
        </h2>
        <gl-button
          :href="newDastSiteProfilePath"
          category="primary"
          variant="success"
          class="gl-ml-auto"
        >
          {{ s__('DastProfiles|New Site Profile') }}
        </gl-button>
      </div>
      <p>
        {{
          s__(
            'DastProfiles|Save commonly used configurations for target sites and scan specifications as profiles. Use these with an on-demand scan.',
          )
        }}
      </p>
    </header>

    <gl-tabs>
      <gl-tab>
        <template #title>
          <span>{{ s__('DastProfiles|Site Profiles') }}</span>
        </template>

        <profiles-list
          :has-error="hasSiteProfilesLoadingError"
          :has-more-profiles-to-load="hasMoreSiteProfiles"
          :is-loading="isLoadingSiteProfiles"
          :profiles-per-page="$options.profilesPerPage"
          :profiles="siteProfiles"
          @loadMoreProfiles="fetchMoreProfiles"
        />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
