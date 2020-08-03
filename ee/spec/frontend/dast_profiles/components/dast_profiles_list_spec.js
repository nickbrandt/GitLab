import { merge } from 'lodash';
import { mount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import DastProfilesList from 'ee/dast_profiles/components/dast_profiles_list.vue';

describe('EE - DastProfilesList', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const defaultProps = {
      profiles: [],
      hasMorePages: false,
      profilesPerPage: 10,
    };

    wrapper = mount(
      DastProfilesList,
      merge(
        {},
        {
          propsData: defaultProps,
        },
        options,
      ),
    );
  };

  const withinComponent = () => within(wrapper.element);
  const getTable = () => withinComponent().getByRole('table', { name: /site profiles/i });
  const getAllRowGroups = () => within(getTable()).getAllByRole('rowgroup');
  const getTableBody = () => {
    // first item is the table head
    const [, tableBody] = getAllRowGroups();
    return tableBody;
  };
  const getAllTableRows = () => within(getTableBody()).getAllByRole('row');
  const getLoadMoreButton = () => wrapper.find('[data-testid="loadMore"]');
  const getAllLoadingIndicators = () => withinComponent().queryAllByTestId('loadingIndicator');
  const getErrorMessage = () => withinComponent().queryByText(/error fetching the profiles list/i);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    const profilesPerPage = 10;

    describe('initial load', () => {
      beforeEach(() => {
        createComponent({ propsData: { isLoading: true, profilesPerPage } });
      });

      it('shows a loading indicator for each profile item', () => {
        expect(getAllLoadingIndicators()).toHaveLength(profilesPerPage);
      });
    });

    describe('with profiles and more to load', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            isLoading: true,
            profilesPerPage,
            profiles: [{}],
            hasMoreProfilesToLoad: true,
          },
        });
      });

      it('does not show a loading indicator for each profile item', () => {
        expect(getAllLoadingIndicators()).toHaveLength(0);
      });

      it('sets the the "load more" button into a loading state', () => {
        expect(getLoadMoreButton().props('loading')).toBe(true);
      });
    });
  });

  describe('with no existing profiles', () => {
    it('shows a message to indicate that no profiles exist', () => {
      createComponent();

      const emptyStateMessage = withinComponent().getByText(/no profiles created yet/i);

      expect(emptyStateMessage).not.toBe(null);
    });
  });

  describe('with existing profiles', () => {
    const profiles = [
      {
        id: 1,
        profileName: 'Profile 1',
        targetUrl: 'http://example-1.com',
        validationStatus: 'Pending',
      },
      {
        id: 2,
        profileName: 'Profile 2',
        targetUrl: 'http://example-2.com',
        validationStatus: 'Pending',
      },
    ];

    const getTableRowForProfile = profile => getAllTableRows()[profiles.indexOf(profile)];

    it('does not show loading indicators', () => {
      createComponent({});
      expect(getAllLoadingIndicators()).toHaveLength(0);
    });

    describe('profiles list', () => {
      beforeEach(() => {
        createComponent({ propsData: { profiles } });
      });

      it('renders a list of profiles', () => {
        expect(getTable()).not.toBe(null);
        expect(getAllTableRows()).toHaveLength(profiles.length);
      });

      it.each(profiles)('renders list item %# correctly', profile => {
        const [
          profileCell,
          targetUrlCell,
          validationStatusCell,
          actionsCell,
        ] = getTableRowForProfile(profile).cells;

        expect(profileCell.innerText).toContain(profile.profileName);
        expect(targetUrlCell.innerText).toContain(profile.targetUrl);
        expect(validationStatusCell.innerText).toContain(profile.validationStatus);
        expect(within(actionsCell).getByRole('button', { name: /edit/i })).not.toBe(null);
      });
    });

    describe('load more profiles', () => {
      it('does not show that there are more projects to be loaded per default', () => {
        createComponent({ propsData: { profiles } });

        expect(getLoadMoreButton().exists()).toBe(false);
      });

      describe('with more profiles', () => {
        beforeEach(() => {
          createComponent({ propsData: { profiles, hasMoreProfilesToLoad: true } });
        });

        it('shows that there are more projects to be loaded', () => {
          expect(getLoadMoreButton().exists()).toBe(true);
        });

        it('emits "loadMore" when the load-more button is clicked', async () => {
          expect(wrapper.emitted('loadMoreProfiles')).toBe(undefined);

          await getLoadMoreButton().trigger('click');

          expect(wrapper.emitted('loadMoreProfiles')).toEqual(expect.any(Array));
        });
      });
    });
  });

  describe('errors', () => {
    it('does not show an error message by default', () => {
      createComponent();

      expect(getErrorMessage()).toBe(null);
    });

    it('shows an error message', () => {
      createComponent({ propsData: { hasError: true } });

      expect(getErrorMessage()).not.toBe(null);
    });
  });
});
