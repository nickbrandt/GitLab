import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlButton } from '@gitlab/ui';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import component from 'ee/environments_dashboard/components/dashboard/dashboard.vue';
import ProjectHeader from 'ee/environments_dashboard/components/dashboard/project_header.vue';
import Environment from 'ee/environments_dashboard/components/dashboard/environment.vue';

import environment from './mock_environment.json';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('dashboard', () => {
  const Component = localVue.extend(component);
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      addPath: 'mock-addPath',
      listPath: 'mock-listPath',
      emptyDashboardSvgPath: '/assets/illustrations/operations-dashboard_empty.svg',
      emptyDashboardHelpPath: '/help/user/operations_dashboard/index.html',
    };

    wrapper = mount(Component, {
      propsData,
      localVue,
      methods: {
        fetchProjects: () => {},
      },
      sync: false,
    });
  });

  it('should match the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders the dashboard title', () => {
    expect(wrapper.find('.js-dashboard-title').text()).toBe('Environments Dashboard');
  });

  describe('add projects button', () => {
    let button;

    beforeEach(() => {
      button = wrapper.find(GlButton);
    });

    it('is labelled correctly', () => {
      expect(button.text()).toBe('Add projects');
    });

    it('should show the modal on click', done => {
      button.trigger('click');
      wrapper.vm.$nextTick(() => {
        expect(wrapper.find(ProjectSelector)).toExist();
        done();
      });
    });
  });

  describe('wrapped components', () => {
    beforeEach(done => {
      wrapper.vm.projects = [
        {
          id: 0,
          name: 'test',
          namespace: { name: 'test', id: 0 },
          environments: [{ ...environment, id: 0 }, environment],
        },
        { id: 1, name: 'test', namespace: { name: 'test', id: 0 }, environments: [environment] },
      ];
      wrapper.vm.$nextTick(() => done());
    });

    describe('project header', () => {
      it('should have one project header per project', () => {
        const headers = wrapper.findAll(ProjectHeader);
        expect(headers.length).toBe(2);
      });
    });

    describe('environment component', () => {
      it('should have one environment component per environment', () => {
        const environments = wrapper.findAll(Environment);
        expect(environments.length).toBe(3);
      });
    });
  });
});
