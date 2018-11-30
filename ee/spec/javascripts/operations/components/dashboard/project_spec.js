import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import Commit from '~/vue_shared/components/commit.vue';
import Project from 'ee/operations/components/dashboard/project.vue';
import ProjectHeader from 'ee/operations/components/dashboard/project_header.vue';
import Alerts from 'ee/operations/components/dashboard/alerts.vue';
import { getChildInstances } from '../../helpers';
import { mockOneProject } from '../../mock_data';

describe('project component', () => {
  const ProjectComponent = Vue.extend(Project);
  const ProjectHeaderComponent = Vue.extend(ProjectHeader);
  const AlertsComponent = Vue.extend(Alerts);
  const CommitComponent = Vue.extend(Commit);
  let vm;

  beforeEach(() => {
    vm = mountComponentWithStore(ProjectComponent, {
      props: {
        project: mockOneProject,
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('wrapped components', () => {
    describe('project header', () => {
      it('binds project', () => {
        const [header] = getChildInstances(vm, ProjectHeaderComponent);

        expect(header.project).toEqual(mockOneProject);
      });
    });

    describe('alerts', () => {
      let alert;

      beforeEach(() => {
        [alert] = getChildInstances(vm, AlertsComponent);
      });

      it('binds alert count to count', () => {
        expect(alert.count).toBe(mockOneProject.alert_count);
      });

      it('binds last alert', () => {
        expect(alert.lastAlert).toEqual(mockOneProject.last_alert);
      });
    });

    describe('commit', () => {
      let commits;
      let commit;

      beforeEach(() => {
        commits = getChildInstances(vm, CommitComponent);
        [commit] = commits;
      });

      it('renders', () => {
        expect(commits.length).toBe(1);
      });

      it('binds commitRef', () => {
        expect(commit.commitRef).toBe(vm.commitRef);
      });

      it('binds short_id to shortSha', () => {
        expect(commit.shortSha).toBe(vm.project.last_deployment.commit.short_id);
      });

      it('binds commitUrl', () => {
        expect(commit.commitUrl).toBe(vm.project.last_deployment.commit.commit_url);
      });

      it('binds title', () => {
        expect(commit.title).toBe(vm.project.last_deployment.commit.title);
      });

      it('binds author', () => {
        expect(commit.author).toBe(vm.author);
      });

      it('binds tag', () => {
        expect(commit.tag).toBe(vm.project.last_deployment.tag);
      });
    });

    describe('last deploy', () => {
      it('renders calendar icon', () => {
        expect(vm.$el.querySelector('.ic-calendar')).not.toBe(null);
      });

      it('renders time ago of last deploy', () => {
        const timeago = '1 day ago';
        const container = vm.$el.querySelector('.js-project-container');

        expect(container.innerText.trim()).toBe(timeago);
      });
    });
  });
});
