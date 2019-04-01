import createStore from 'ee/security_dashboard/store/index';
import * as vulnerabilitiesMutationTypes from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import { DAYS } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';

describe('syncWithRouter', () => {
  let store;
  const noop = () => {};

  beforeEach(() => {
    store = createStore();
  });

  it('updates store after URL changes', () => {
    const page = 3;
    const days = DAYS.SIXTY;
    const query = { example: ['test'], page, days };

    jest.spyOn(store, 'dispatch');

    const routerPush = store.$router.push.bind(store.$router);
    jest.spyOn(store.$router, 'push');
    routerPush({ name: 'dashboard', query });

    // Assert no implicit synchronous recursive calls occurred
    expect(store.$router.push).not.toHaveBeenCalled();

    expect(store.dispatch).toHaveBeenCalledWith(`filters/setAllFilters`, query);
    expect(store.dispatch).toHaveBeenCalledWith(`vulnerabilities/setVulnerabilitiesPage`, page);
    expect(store.dispatch).toHaveBeenCalledWith(
      `vulnerabilities/setVulnerabilitiesHistoryDayRange`,
      days,
    );
  });

  it("doesn't update the store if the URL update originated from the moderator", () => {
    const query = { example: ['test'] };

    jest.spyOn(store, 'commit').mockImplementation(noop);

    store.$router.push({ name: 'dashboard', query, params: { updatedFromState: true } });

    expect(store.commit).toHaveBeenCalledTimes(0);
  });

  it('it updates the route after a successful vulnerability retrieval', () => {
    const activeFilters = store.getters['filters/activeFilters'];
    const page = 2;

    jest.spyOn(store.$router, 'push').mockImplementation(noop);

    store.commit(
      `vulnerabilities/${vulnerabilitiesMutationTypes.RECEIVE_VULNERABILITIES_SUCCESS}`,
      { pageInfo: { page } },
    );

    expect(store.$router.push).toHaveBeenCalledTimes(1);
    expect(store.$router.push).toHaveBeenCalledWith({
      name: 'dashboard',
      query: expect.objectContaining({ ...activeFilters, page }),
      params: { updatedFromState: true },
    });
  });

  it('it updates the route after changing the vulnerability history day range', () => {
    const days = DAYS.SIXTY;

    jest.spyOn(store.$router, 'push').mockImplementation(noop);

    store.commit(
      `vulnerabilities/${vulnerabilitiesMutationTypes.SET_VULNERABILITIES_HISTORY_DAY_RANGE}`,
      days,
    );

    expect(store.$router.push).toHaveBeenCalledTimes(1);
    expect(store.$router.push).toHaveBeenCalledWith({
      name: 'dashboard',
      query: expect.objectContaining({ days }),
      params: { updatedFromState: true },
    });
  });
});
