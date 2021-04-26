import { GlAlert, GlDrawer, GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import AlertDrawer from 'ee/threat_monitoring/components/alerts/alert_drawer.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import getAlertDetailsQuery from '~/vue_shared/alert_details/graphql/queries/alert_details.query.graphql';
import { erroredGetAlertDetailsQuerySpy, getAlertDetailsQuerySpy } from '../../mocks/mock_apollo';
import { mockAlertDetails } from '../../mocks/mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

let localVue;

describe('Alert Drawer', () => {
  let wrapper;
  const DEFAULT_PROJECT_PATH = '#';

  const mutateSpy = jest
    .fn()
    .mockResolvedValue({ data: { createAlertIssue: { errors: [], issue: { iid: '03' } } } });
  let querySpy;

  const createMockApolloProvider = (query) => {
    localVue.use(VueApollo);
    return createMockApollo([[getAlertDetailsQuery, query]]);
  };

  const shallowApolloMock = ({ loading = false, mutate = mutateSpy }) => ({
    mutate,
    queries: { alertDetails: { loading } },
  });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCreateIssueButton = () => wrapper.findByTestId('create-issue-button');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findIssueLink = () => wrapper.findByTestId('issue-link');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDetails = () => wrapper.findByTestId('details-list');

  const createWrapper = ({
    $apollo,
    apolloSpy = getAlertDetailsQuerySpy,
    mount = shallowMountExtended,
    props = {},
  } = {}) => {
    let apolloOptions;
    if ($apollo) {
      apolloOptions = {
        mocks: {
          $apollo,
        },
      };
    } else {
      localVue = createLocalVue();
      querySpy = apolloSpy;
      const mockApollo = createMockApolloProvider(querySpy);
      apolloOptions = {
        localVue,
        apolloProvider: mockApollo,
      };
    }

    wrapper = mount(AlertDrawer, {
      propsData: {
        isAlertDrawerOpen: true,
        projectId: '1',
        selectedAlert: mockAlertDetails,
        ...props,
      },
      provide: {
        projectPath: DEFAULT_PROJECT_PATH,
      },
      stubs: { GlDrawer },
      ...apolloOptions,
    });
  };
  describe('default', () => {
    it.each`
      component                  | status                | findComponent            | state    | mount
      ${'alert'}                 | ${'does not display'} | ${findAlert}             | ${false} | ${undefined}
      ${'"Create Issue" button'} | ${'does not display'} | ${findCreateIssueButton} | ${false} | ${undefined}
      ${'details list'}          | ${'does display'}     | ${findDetails}           | ${true}  | ${undefined}
      ${'drawer'}                | ${'does display'}     | ${findDrawer}            | ${true}  | ${undefined}
      ${'issue link'}            | ${'does display'}     | ${findIssueLink}         | ${true}  | ${undefined}
      ${'loading icon'}          | ${'does not display'} | ${findLoadingIcon}       | ${false} | ${mountExtended}
    `('$status the $component', ({ findComponent, state, mount }) => {
      createWrapper({ $apollo: shallowApolloMock({}), mount });
      expect(findComponent().exists()).toBe(state);
    });
  });

  it('displays the issue link if an alert already has an issue associated with it', () => {
    createWrapper();
    expect(findIssueLink().exists()).toBe(true);
    expect(findIssueLink().attributes('href')).toBe('/#/-/issues/02');
  });

  it('displays the loading icon when retrieving the alert details', () => {
    createWrapper({ $apollo: shallowApolloMock({ loading: true }) });
    expect(findLoadingIcon().exists()).toBe(true);
    expect(findDetails().exists()).toBe(false);
  });

  it('displays the alert when there was an error retrieving alert details', async () => {
    createWrapper({ apolloSpy: erroredGetAlertDetailsQuerySpy });
    await wrapper.vm.$nextTick();
    expect(findAlert().exists()).toBe(true);
  });

  describe('creating an issue', () => {
    it('navigates to the created issue when the "Create Issue" button is clicked', async () => {
      createWrapper({
        $apollo: shallowApolloMock({}),
        props: { selectedAlert: {} },
      });
      expect(findCreateIssueButton().exists()).toBe(true);
      findCreateIssueButton().vm.$emit('click');
      await waitForPromises;
      expect(mutateSpy).toHaveBeenCalledTimes(1);
      await wrapper.vm.$nextTick();
      expect(visitUrl).toHaveBeenCalledWith('/#/-/issues/03');
    });

    it('displays the alert when there was an error creating an issue', async () => {
      const erroredMutateSpy = jest
        .fn()
        .mockResolvedValue({ data: { createAlertIssue: { errors: ['test'] } } });

      createWrapper({
        $apollo: shallowApolloMock({ mutate: erroredMutateSpy }),
        props: { selectedAlert: {} },
      });
      expect(findCreateIssueButton().exists()).toBe(true);
      findCreateIssueButton().vm.$emit('click');
      await waitForPromises;
      expect(erroredMutateSpy).toHaveBeenCalledTimes(1);
      await wrapper.vm.$nextTick();
      expect(visitUrl).not.toHaveBeenCalled();
      await wrapper.vm.$nextTick();
      expect(findAlert().exists()).toBe(true);
    });
  });
});
