import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import createApolloProvider from 'helpers/mock_apollo_helper';
import dastSiteValidationsQuery from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validations.query.graphql';
import Component from 'ee/security_configuration/dast_profiles/components/dast_site_profiles_list.vue';
import ProfilesList from 'ee/security_configuration/dast_profiles/components/dast_profiles_list.vue';
import { updateSiteProfilesStatuses } from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import { siteProfiles } from '../mocks/mock_data';
import * as responses from '../mocks/apollo_mock';

jest.mock('ee/security_configuration/dast_profiles/graphql/cache_utils');

updateSiteProfilesStatuses.mockImplementation(() => ({
  updateSiteProfilesStatuses: jest.fn(),
}));

describe('EE - DastSiteProfileList', () => {
  let localVue;
  let wrapper;
  let requestHandlers;

  const defaultProps = {
    profiles: [],
    tableLabel: 'Site profiles',
    fields: ['profileName', 'targetUrl', 'validationStatus'],
    profilesPerPage: 10,
    errorMessage: '',
    errorDetails: [],
    fullPath: '/namespace/project',
    hasMoreProfilesToLoad: false,
    isLoading: false,
  };

  const createMockApolloProvider = handlers => {
    localVue.use(VueApollo);

    requestHandlers = {
      dastSiteValidations: jest.fn().mockResolvedValue(responses.dastSiteValidations()),
      ...handlers,
    };

    return createApolloProvider([[dastSiteValidationsQuery, requestHandlers.dastSiteValidations]]);
  };

  const wrapperFactory = (mountFn = shallowMount) => (options = {}, handlers) => {
    localVue = createLocalVue();
    const apolloProvider = handlers && createMockApolloProvider(handlers);
    wrapper = mountFn(
      Component,
      merge(
        {
          propsData: defaultProps,
          provide: {
            glFeatures: { securityOnDemandScansSiteValidation: true },
          },
        },
        { ...options, localVue, apolloProvider },
      ),
    );
  };
  const createComponent = wrapperFactory();
  const createFullComponent = wrapperFactory(mount);

  const withinComponent = () => within(wrapper.element);
  const getTable = () => withinComponent().getByRole('table', { name: /profiles/i });
  const getAllRowGroups = () => within(getTable()).getAllByRole('rowgroup');
  const getTableBody = () => {
    // first item is the table head
    const [, tableBody] = getAllRowGroups();
    return tableBody;
  };
  const getAllTableRows = () => within(getTableBody()).getAllByRole('row');
  const getTableRowForProfile = profile => getAllTableRows()[siteProfiles.indexOf(profile)];

  const findProfileList = () => wrapper.find(ProfilesList);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders profile list properly', () => {
    createComponent({
      propsData: { profiles: siteProfiles },
    });

    expect(findProfileList()).toExist();
  });

  it('passes down the props properly', () => {
    createFullComponent();

    expect(findProfileList().props()).toEqual(defaultProps);
  });

  it('sets listeners on profile list component', () => {
    const inputHandler = jest.fn();
    createComponent({
      listeners: {
        input: inputHandler,
      },
    });
    findProfileList().vm.$emit('input');

    expect(inputHandler).toHaveBeenCalled();
  });

  describe('with site validation enabled', () => {
    const [pendingValidation, inProgressValidation] = siteProfiles;
    const urlsPendingValidation = [
      pendingValidation.normalizedTargetUrl,
      inProgressValidation.normalizedTargetUrl,
    ];

    beforeEach(() => {
      createFullComponent(
        { propsData: { profiles: siteProfiles } },
        {
          dastSiteValidations: jest.fn().mockResolvedValue(
            responses.dastSiteValidations([
              {
                normalizedTargetUrl: pendingValidation.normalizedTargetUrl,
                status: 'FAILED_VALIDATION',
              },
              {
                normalizedTargetUrl: inProgressValidation.normalizedTargetUrl,
                status: 'PASSED_VALIDATION',
              },
            ]),
          ),
        },
      );
    });

    describe.each`
      status           | statusEnum                 | label                  | hasValidateButton
      ${'pending'}     | ${'PENDING_VALIDATION'}    | ${''}                  | ${true}
      ${'in-progress'} | ${'INPROGRESS_VALIDATION'} | ${'Validating...'}     | ${false}
      ${'passed'}      | ${'PASSED_VALIDATION'}     | ${'Validated'}         | ${false}
      ${'failed'}      | ${'FAILED_VALIDATION'}     | ${'Validation failed'} | ${true}
    `('profile with validation $status', ({ statusEnum, label, hasValidateButton }) => {
      const profile = siteProfiles.find(({ validationStatus }) => validationStatus === statusEnum);

      it(`should show correct label`, () => {
        const validationStatusCell = getTableRowForProfile(profile).cells[2];
        expect(validationStatusCell.innerText).toContain(label);
      });

      it(`should ${hasValidateButton ? '' : 'not '}render validate button`, () => {
        const actionsCell = getTableRowForProfile(profile).cells[3];
        const validateButton = within(actionsCell).queryByRole('button', {
          name: /validate/i,
        });

        if (hasValidateButton) {
          expect(validateButton).not.toBeNull();
        } else {
          expect(validateButton).toBeNull();
        }
      });
    });

    it('fetches validation statuses for all profiles that are being validated and updates the cache', async () => {
      expect(requestHandlers.dastSiteValidations).toHaveBeenCalledWith({
        fullPath: defaultProps.fullPath,
        urls: urlsPendingValidation,
      });
      expect(updateSiteProfilesStatuses).toHaveBeenCalledTimes(2);
    });

    it.each`
      nthCall | normalizedTargetUrl                         | status
      ${1}    | ${pendingValidation.normalizedTargetUrl}    | ${'FAILED_VALIDATION'}
      ${2}    | ${inProgressValidation.normalizedTargetUrl} | ${'PASSED_VALIDATION'}
    `(
      'in the local cache, profile with normalized URL $normalizedTargetUrl has its status set to $status',
      ({ nthCall, normalizedTargetUrl, status }) => {
        expect(updateSiteProfilesStatuses).toHaveBeenNthCalledWith(nthCall, {
          fullPath: defaultProps.fullPath,
          normalizedTargetUrl,
          status,
          store: wrapper.vm.$apolloProvider.defaultClient,
        });
      },
    );
  });

  describe('without site validation enabled', () => {
    beforeEach(() => {
      createFullComponent({
        provide: {
          glFeatures: { securityOnDemandScansSiteValidation: false },
        },
        propsData: { siteProfiles },
      });
    });

    it.each(siteProfiles)('profile %# should not have validate button and status', profile => {
      const [, , validationStatusCell, actionsCell] = getTableRowForProfile(profile).cells;

      expect(within(actionsCell).queryByRole('button', { name: /validate/i })).toBe(null);
      expect(validationStatusCell.innerText).toBe('');
    });
  });
});
