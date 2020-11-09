<script>
import {
  GlFormGroup,
  GlFormCheckbox,
  GlFormInput,
  GlSprintf,
  GlLink,
  GlButton,
  GlCard,
  GlFormRadioGroup,
  GlFormRadio,
} from '@gitlab/ui';
import eventHub from '../event_hub';

export default {
  name: 'JiraIssuesFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlSprintf,
    GlLink,
    GlButton,
    GlCard,
    GlFormRadioGroup,
    GlFormRadio,
  },
  props: {
    showJiraIssuesIntegration: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialEnableJiraIssues: {
      type: Boolean,
      required: false,
      default: null,
    },
    initialEnableJiraIssuesFromVulnerabilities: {
      type: Boolean,
      required: false,
      default: null,
    },
    initialProjectKey: {
      type: String,
      required: false,
      default: null,
    },
    initialIssueKey: {
      type: String,
      required: false,
      default: null,
    },
    issueTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    gitlabIssuesEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    upgradePlanPath: {
      type: String,
      required: false,
      default: null,
    },
    editProjectPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      enableJiraIssues: this.initialEnableJiraIssues,
      enableJiraIssuesFromVulnerabilities: this.initialEnableJiraIssuesFromVulnerabilities,
      projectKey: this.initialProjectKey,
      issueKey: this.initialIssueKey,
      validated: false,
    };
  },
  computed: {
    validProjectKey() {
      return !this.enableJiraIssues || Boolean(this.projectKey) || !this.validated;
    },
  },
  created() {
    eventHub.$on('validateForm', this.validateForm);
  },
  beforeDestroy() {
    eventHub.$off('validateForm', this.validateForm);
  },
  methods: {
    validateForm() {
      this.validated = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="s__('JiraService|View Jira issues in GitLab')"
      label-for="jira-issue-settings"
    >
      <div id="jira-issue-settings">
        <p>
          {{
            s__(
              'JiraService|Work on Jira issues without leaving GitLab. Adds a Jira menu to access your list of Jira issues and view any issue as read-only.',
            )
          }}
        </p>
        <template v-if="showJiraIssuesIntegration">
          <input name="service[issues_enabled]" type="hidden" :value="enableJiraIssues || false" />
          <gl-form-checkbox v-model="enableJiraIssues">
            {{ s__('JiraService|Enable Jira issues') }}
            <template #help>
              {{
                s__(
                  'JiraService|Warning: All GitLab users that have access to this GitLab project will be able to view all issues from the Jira project specified below.',
                )
              }}
            </template>
          </gl-form-checkbox>
          <input name="service[vulnerabilities_enabled]" type="hidden" :value="enableJiraIssuesFromVulnerabilities || false" />
          <gl-form-checkbox v-model="enableJiraIssuesFromVulnerabilities">
            {{ s__('JiraService|Enable Jira issue creation from vulnerabilities') }}
            <template #help>
              {{
                s__(
                  'JiraService|Issues created from vulnerabilities in this project will be Jira issues, even if GitLab issues are enabled.',
                )
              }}
            </template>
          </gl-form-checkbox>
          <gl-form-group
            v-if="enableJiraIssuesFromVulnerabilities"
            :label="s__('JiraService|Jira issue type')"
            label-for="service_vulnerabilities_issuetype"
          >
            <p>
            {{
              s__(
                'JiraService|Define the type of Jira issue to create from a vulnerability.',
              )
            }}
            </p>
            <p v-if="!issueTypes.length">
            {{
              s__(
                'JiraService|Click on Test settings button to load available issue types.',
              )
            }}
            </p>
            <gl-form-radio-group v-model="issueKey" name="service[vulnerabilities_issuetype]">
              <gl-form-radio
                v-for="issuetype in issueTypes"
                :key="issuetype.name"
                :value="issuetype.id"
              >
                {{ issuetype.name }}
              </gl-form-radio>
            </gl-form-radio-group>
          </gl-form-group>
        </template>
        <gl-card v-else class="gl-mt-7">
          <strong>{{ __('This is a Premium feature') }}</strong>
          <p>{{ __('Upgrade your plan to enable this feature of the Jira Integration.') }}</p>
          <gl-button
            v-if="upgradePlanPath"
            category="primary"
            variant="info"
            :href="upgradePlanPath"
            target="_blank"
          >
            {{ __('Upgrade your plan') }}
          </gl-button>
        </gl-card>
      </div>
    </gl-form-group>
    <template v-if="showJiraIssuesIntegration">
      <gl-form-group
        :label="s__('JiraService|Jira project key')"
        label-for="service_project_key"
        :invalid-feedback="__('This field is required.')"
        :state="validProjectKey"
      >
        <gl-form-input
          id="service_project_key"
          v-model="projectKey"
          name="service[project_key]"
          :placeholder="s__('JiraService|e.g. AB')"
          :required="enableJiraIssues"
          :state="validProjectKey"
          :disabled="!enableJiraIssues"
        />
      </gl-form-group>
      <p v-if="gitlabIssuesEnabled">
        <gl-sprintf
          :message="
            s__(
              'JiraService|Displaying Jira issues while leaving the GitLab issue functionality enabled might be confusing. Consider %{linkStart}disabling GitLab issues%{linkEnd} if they won’t otherwise be used.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="editProjectPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </div>
</template>
