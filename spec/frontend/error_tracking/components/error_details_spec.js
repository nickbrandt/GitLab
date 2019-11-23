import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlLink } from '@gitlab/ui';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import ErrorDetails from '~/error_tracking/components/error_details.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorDetails', () => {
  let store;
  let wrapper;
  let actions;
  let getters;

  function mountComponent() {
    wrapper = shallowMount(ErrorDetails, {
      localVue,
      store,
      propsData: {
        issueDetailsPath: '/123/details',
        issueStackTracePath: '/stacktrace',
        projectIssuesPath: '/test-project/issues/',
        csrfToken: 'fakeToken',
      },
    });
  }

  beforeEach(() => {
    actions = {
      startPollingDetails: () => {},
      startPollingStacktrace: () => {},
    };

    getters = {
      sentryUrl: () => 'sentry.io',
      stacktrace: () => [{ context: [1, 2], lineNo: 53, filename: 'index.js' }],
    };

    const state = {
      error: {},
      loading: true,
      stacktraceData: {},
      loadingStacktrace: true,
    };

    store = new Vuex.Store({
      modules: {
        details: {
          namespaced: true,
          actions,
          state,
          getters,
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('should show spinner while loading', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(GlLink).exists()).toBe(false);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
    });
  });

  describe('Error details', () => {
    it('should show Sentry error details without stacktrace', () => {
      store.state.details.loading = false;
      store.state.details.error.id = 1;
      mountComponent();
      expect(wrapper.find(GlLink).exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(Stacktrace).exists()).toBe(false);
    });

    it('should create an issue with title and description', () => {
      store.state.details.loading = false;
      store.state.details.error = {
        id: 1,
        title: 'Issue title',
        external_url: 'http://sentry.gitlab.net/gitlab',
        first_seen: '2017-05-26T13:32:48Z',
        last_seen: '2018-05-26T13:32:48Z',
        count: 12,
        user_count: 2,
      };
      mountComponent();

      const form = wrapper.find({ ref: 'sentryIssueForm' });
      const csrfTokenInput = wrapper.find('input[name="authenticity_token"]');
      const issueTitleInput = wrapper.find('input[name="issue[title]"]');
      const issueDescriptionInput = wrapper.find('input[name="issue[description]"]');

      expect(form).toExist();
      expect(csrfTokenInput.attributes('value')).toBe('fakeToken');
      expect(issueTitleInput.attributes('value')).toContain(wrapper.vm.issueTitle);
      expect(issueDescriptionInput.attributes('value')).toContain(wrapper.vm.issueDescription);
    });

    describe('Stacktrace', () => {
      it('should show stacktrace', () => {
        store.state.details.loading = false;
        store.state.details.error.id = 1;
        store.state.details.loadingStacktrace = false;
        mountComponent();
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.find(Stacktrace).exists()).toBe(true);
      });

      it('should NOT show stacktrace if no entries', () => {
        store.state.details.loading = false;
        store.state.details.loadingStacktrace = false;
        store.getters = { 'details/sentryUrl': () => 'sentry.io', 'details/stacktrace': () => [] };
        mountComponent();
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.find(Stacktrace).exists()).toBe(false);
      });
    });
  });
});
