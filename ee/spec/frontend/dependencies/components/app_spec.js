import { createLocalVue, shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import createStore from 'ee/dependencies/store';
import { DEPENDENCY_LIST_TYPES } from 'ee/dependencies/store/constants';
import { REPORT_STATUS } from 'ee/dependencies/store/modules/list/constants';
import DependenciesApp from 'ee/dependencies/components/app.vue';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from 'ee/dependencies/components/dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from 'ee/dependencies/components/paginated_dependencies_table.vue';

describe('DependenciesApp component', () => {
  let store;
  let wrapper;
  const listType = DEPENDENCY_LIST_TYPES.all;

  const basicAppProps = {
    endpoint: '/foo',
    emptyStateSvgPath: '/bar.svg',
    documentationPath: TEST_HOST,
  };

  const factory = (props = basicAppProps) => {
    const localVue = createLocalVue();

    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(DependenciesApp, {
      localVue,
      store,
      sync: false,
      propsData: { ...props },
    });
  };

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    let dependencies;

    beforeEach(() => {
      factory();
    });

    it('dispatches the correct initial actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        [`${listType}/setDependenciesEndpoint`, basicAppProps.endpoint],
        [`${listType}/fetchDependencies`, undefined],
      ]);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('given a list of dependencies and ok report', () => {
      beforeEach(() => {
        dependencies = ['foo', 'bar'];

        Object.assign(store.state[listType], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[listType].pageInfo.total = 100;
        store.state[listType].reportInfo.status = REPORT_STATUS.ok;

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace: listType,
        });
      });
    });

    describe('given the dependency list job has not yet run', () => {
      beforeEach(() => {
        dependencies = [];

        Object.assign(store.state[listType], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[listType].pageInfo.total = 0;
        store.state[listType].reportInfo.status = REPORT_STATUS.jobNotSetUp;

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    describe('given the dependency list job failed', () => {
      beforeEach(() => {
        dependencies = [];

        Object.assign(store.state[listType], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[listType].pageInfo.total = 0;
        store.state[listType].reportInfo.status = REPORT_STATUS.jobFailed;
        store.state[listType].reportInfo.jobPath = '/jobs/foo/321';

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the job failure alert', () => {
        expectComponentWithProps(DependencyListJobFailedAlert, {
          jobPath: store.state[listType].reportInfo.jobPath,
        });
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace: listType,
        });
      });

      describe('when the job failure alert emits the close event', () => {
        beforeEach(() => {
          const alertWrapper = wrapper.find(DependencyListJobFailedAlert);
          alertWrapper.vm.$emit('close');
          return wrapper.vm.$nextTick();
        });

        it('does not render the job failure alert', () => {
          expect(wrapper.find(DependencyListJobFailedAlert).exists()).toBe(false);
        });
      });
    });

    describe('given a dependency list which is known to be incomplete', () => {
      beforeEach(() => {
        dependencies = ['foo', 'bar'];

        Object.assign(store.state[listType], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[listType].pageInfo.total = 100;
        store.state[listType].reportInfo.status = REPORT_STATUS.incomplete;

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the incomplete-list alert', () => {
        const alert = wrapper.find(DependencyListIncompleteAlert);
        expect(alert.isVisible()).toBe(true);
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace: listType,
        });
      });

      describe('when the incomplete-list alert emits the close event', () => {
        beforeEach(() => {
          const alertWrapper = wrapper.find(DependencyListIncompleteAlert);
          alertWrapper.vm.$emit('close');
          return wrapper.vm.$nextTick();
        });

        it('does not render the incomplete-list alert', () => {
          expect(wrapper.find(DependencyListIncompleteAlert).exists()).toBe(false);
        });
      });
    });

    describe('given a fetch error', () => {
      beforeEach(() => {
        dependencies = [];

        Object.assign(store.state[listType], {
          initialized: true,
          isLoading: false,
          errorLoading: true,
          dependencies,
        });

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace: listType,
        });
      });
    });
  });
});
