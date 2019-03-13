import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Commit from '~/vue_shared/components/commit.vue';
import Project from 'ee/operations/components/dashboard/new_project.vue';
import ProjectHeader from 'ee/operations/components/dashboard/new_project_header.vue';
import Alerts from 'ee/operations/components/dashboard/new_alerts.vue';
import store from 'ee/operations/store';
import { mockOneProject } from '../../new_mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('project component', () => {
  const ProjectComponent = localVue.extend(Project);
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ProjectComponent, {
      sync: false,
      store,
      localVue,
      propsData: { project: mockOneProject },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('wrapped components', () => {
    describe('project header', () => {
      it('binds project', () => {
        const header = wrapper.find(ProjectHeader);

        expect(header.props('project')).toEqual(mockOneProject);
      });
    });

    describe('alerts', () => {
      it('binds alert count to count', () => {
        const alert = wrapper.find(Alerts);

        expect(alert.props('count')).toBe(mockOneProject.alert_count);
      });
    });

    describe('commit', () => {
      let commit;

      beforeEach(() => {
        commit = wrapper.find(Commit);
      });

      it('binds commitRef', () => {
        expect(commit.props('commitRef')).toBe(wrapper.vm.commitRef);
      });

      it('binds short_id to shortSha', () => {
        expect(commit.props('shortSha')).toBe(
          wrapper.props().project.last_pipeline.commit.short_id,
        );
      });

      it('binds commitUrl', () => {
        expect(commit.props('commitUrl')).toBe(
          wrapper.props().project.last_pipeline.commit.commit_url,
        );
      });

      it('binds title', () => {
        expect(commit.props('title')).toBe(wrapper.props().project.last_pipeline.commit.title);
      });

      it('binds author', () => {
        expect(commit.props('author')).toBe(wrapper.props().project.last_pipeline.commit.author);
      });

      it('binds tag', () => {
        expect(commit.props('tag')).toBe(wrapper.props().project.last_pipeline.ref.tag);
      });
    });

    describe('deploy finished at', () => {
      it('renders clock icon', () => {
        expect(wrapper.contains('.js-dashboard-project-clock-icon')).toBe(true);
      });

      it('renders time ago of finished time', () => {
        const timeago = '1 day ago';
        const container = wrapper.element.querySelector('.js-dashboard-project-time-ago');

        expect(container.innerText.trim()).toBe(timeago);
      });
    });
  });
});
