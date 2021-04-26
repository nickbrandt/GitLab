<script>
import { GlAlert, GlButton, GlDrawer, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { capitalizeFirstCharacter, splitCamelCase } from '~/lib/utils/text_utility';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import createIssueMutation from '~/vue_shared/alert_details/graphql/mutations/alert_issue_create.mutation.graphql';
import getAlertDetailsQuery from '~/vue_shared/alert_details/graphql/queries/alert_details.query.graphql';
import { HIDDEN_VALUES } from './constants';

export default {
  HEADER_HEIGHT: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  i18n: {
    CREATE_ISSUE: __('Create incident'),
    ERROR: __('There was an error.'),
  },
  components: {
    GlAlert,
    GlButton,
    GlDrawer,
    GlLink,
    GlLoadingIcon,
  },
  inject: ['projectPath'],
  apollo: {
    alertDetails: {
      query: getAlertDetailsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          alertId: this.selectedAlert.iid,
        };
      },
      update(data) {
        return data?.project?.alertManagementAlerts?.nodes?.[0] ?? null;
      },
      error() {
        this.errored = true;
      },
    },
  },
  props: {
    isAlertDrawerOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    selectedAlert: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      alertDetails: {},
      errored: false,
      creatingIssue: false,
    };
  },
  computed: {
    alertIssuePath() {
      const issueIid = this.selectedAlert.issue?.iid;
      return issueIid ? this.getIssuePath(issueIid) : '';
    },
    curatedAlertDetails() {
      return Object.entries({ ...this.alertDetails, ...this.alertDetails?.details }).reduce(
        (acc, [key, value]) => {
          return HIDDEN_VALUES.includes(key) || !value ? acc : [...acc, [key, value]];
        },
        [],
      );
    },
    hasIssue() {
      return Boolean(this.selectedAlert.issue);
    },
    issueText() {
      return `#${this.selectedAlert.issue.iid}`;
    },
    isLoadingDetails() {
      return this.$apollo.queries.alertDetails.loading;
    },
  },
  methods: {
    async createIssue() {
      this.creatingIssue = true;

      try {
        const response = await this.$apollo.mutate({
          mutation: createIssueMutation,
          variables: {
            iid: this.selectedAlert.iid,
            projectPath: this.projectPath,
          },
        });

        const { errors, issue } = response.data.createAlertIssue;
        if (errors?.length) {
          throw new Error();
        }
        visitUrl(this.getIssuePath(issue.iid));
      } catch {
        this.handleAlertError();
        this.creatingIssue = false;
      }
    },
    getIssuePath(issueIid) {
      return joinPaths(gon.relative_url_root || '/', this.projectPath, '-', 'issues', issueIid);
    },
    handleAlertError() {
      this.errored = true;
    },
    humanizeText(text) {
      return capitalizeFirstCharacter(splitCamelCase(text));
    },
  },
};
</script>
<template>
  <gl-drawer
    :z-index="252"
    :open="isAlertDrawerOpen"
    :header-height="$options.HEADER_HEIGHT"
    @close="$emit('deselect-alert')"
  >
    <template #header>
      <div>
        <h5 class="gl-mb-5">{{ selectedAlert.title }}</h5>
        <div>
          <gl-link v-if="hasIssue" :href="alertIssuePath" data-testid="issue-link">
            {{ issueText }}
          </gl-link>
          <gl-button
            v-else
            category="primary"
            variant="confirm"
            :disabled="errored"
            :loading="creatingIssue"
            data-testid="create-issue-button"
            @click="createIssue"
          >
            {{ $options.i18n.CREATE_ISSUE }}
          </gl-button>
        </div>
      </div>
    </template>
    <gl-alert v-if="errored" variant="danger" :dismissable="false" contained>
      {{ $options.i18n.ERROR }}
    </gl-alert>
    <gl-loading-icon v-if="isLoadingDetails" size="lg" color="dark" class="gl-mt-5" />
    <div v-else data-testid="details-list">
      <div v-for="[key, value] in curatedAlertDetails" :key="key" class="gl-mb-3">
        <div>{{ humanizeText(key) }}</div>
        <b>{{ value }}</b>
      </div>
    </div>
  </gl-drawer>
</template>
