<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

import savedContentMetaQuery from '../graphql/queries/saved_content_meta.query.graphql';
import appDataQuery from '../graphql/queries/app_data.query.graphql';
import { HOME_ROUTE } from '../router/constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  props: {
    mergeRequestsIllustrationPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    savedContentMeta: {
      query: savedContentMetaQuery,
    },
    appData: {
      query: appDataQuery,
    },
  },
  computed: {
    updatedFileDescription() {
      const { sourcePath } = this.appData;

      return sprintf(s__('Update %{sourcePath} file'), { sourcePath });
    },
  },
  created() {
    if (!this.savedContentMeta) {
      this.$router.push(HOME_ROUTE);
    }
  },
  messages: {
    title: s__('StaticSiteEditor|Your merge request is ready to be managed'),
    primaryButtonText: __('View merge request'),
    returnToSiteBtnText: s__('StaticSiteEditor|Return to site'),
    mergeRequestInstructionsHeading: s__(
      'StaticSiteEditor|A couple of things you need to do to get your changes visible:',
    ),
    addDescriptionInstruction: s__(
      'StaticSiteEditor|1. Add a description to this merge request to explain why the change is being made.',
    ),
    assignMergeRequestInstruction: s__(
      'StaticSiteEditor|2. Assign this merge request to a person who can accept the changes so that it can be visible on the site.',
    ),
  },
};
</script>
<template>
  <div v-if="savedContentMeta" class="container">
    <div
      class="gl-absolute gl-left-0 gl-right-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
    >
      <div class="container gl-py-4">
        <gl-button
          v-if="appData.returnUrl"
          ref="returnToSiteButton"
          class="gl-mr-5"
          :href="appData.returnUrl"
          >{{ $options.messages.returnToSiteBtnText }}</gl-button
        >
        <strong>
          {{ updatedFileDescription }}
        </strong>
      </div>
    </div>
    <gl-empty-state
      :primary-button-text="$options.messages.primaryButtonText"
      :title="$options.messages.title"
      :primary-button-link="savedContentMeta.mergeRequest.url"
      :svg-path="mergeRequestsIllustrationPath"
    >
      <template #description>
        <p>{{ $options.messages.mergeRequestInstructionsHeading }}</p>
        <p>{{ $options.messages.addDescriptionInstruction }}</p>
        <p>{{ $options.messages.assignMergeRequestInstruction }}</p>
      </template>
    </gl-empty-state>
  </div>
</template>
