<script>
import { mapActions } from 'vuex';
import timeago from '~/vue_shared/mixins/timeago';
import Icon from '~/vue_shared/components/icon.vue';
import Commit from '~/vue_shared/components/commit.vue';
import DashboardAlerts from './alerts.vue';
import ProjectHeader from './project_header.vue';

export default {
  components: {
    Icon,
    Commit,
    DashboardAlerts,
    ProjectHeader,
  },
  mixins: [timeago],
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    author() {
      return this.hasDeployment && this.project.last_deployment.user
        ? {
            avatar_url: this.project.last_deployment.user.avatar_url,
            path: this.project.last_deployment.user.web_url,
            username: this.project.last_deployment.user.username,
          }
        : null;
    },
    commitRef() {
      return this.hasDeployment && this.project.last_deployment.ref
        ? {
            name: this.project.last_deployment.ref.name,
            ref_url: this.project.last_deployment.ref.ref_path,
          }
        : null;
    },
    hasDeployment() {
      return this.project.last_deployment !== null;
    },
    lastDeployed() {
      return this.hasDeployment ? this.timeFormated(this.project.last_deployment.created_at) : null;
    },
  },
  methods: {
    ...mapActions(['removeProject']),
  },
};
</script>

<template>
  <div class="card">
    <project-header
      :project="project"
      class="card-header"
      @remove="removeProject"
    />
    <div class="card-body">
      <div class="row">
        <div class="col-6 col-sm-4 col-md-6 col-lg-4 pr-1">
          <dashboard-alerts
            :count="project.alert_count"
            :last-alert="project.last_alert"
            :alert-path="project.alert_path"
          />
        </div>
        <template v-if="project.last_deployment">
          <div class="col-6 col-sm-4 col-md-6 col-lg-4 px-1">
            <commit
              :commit-ref="commitRef"
              :short-sha="project.last_deployment.commit.short_id"
              :commit-url="project.last_deployment.commit.commit_url"
              :title="project.last_deployment.commit.title"
              :author="author"
              :tag="project.last_deployment.tag"
            />
          </div>
          <div
            class="js-project-container col-12 col-sm-4 col-md-12 col-lg-4 pl-1 d-flex justify-content-end"
          >
            <div
              class="d-flex align-items-end justify-content-end"
            >
              <div class="prepend-top-default text-secondary d-flex align-items-center flex-wrap">
                <icon
                  name="calendar"
                  class="append-right-4"
                />
                {{ lastDeployed }}
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>
