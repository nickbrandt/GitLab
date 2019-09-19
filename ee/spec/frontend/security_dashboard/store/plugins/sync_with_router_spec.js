import createStore from 'ee/security_dashboard/store/index';
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

  it('sets page to 1 if query query string does not contain a page param after URL changes', () => {
    const page = undefined;
    const days = DAYS.SIXTY;
    const query = { example: ['test'], page, days };

    jest.spyOn(store, 'dispatch');

    const routerPush = store.$router.push.bind(store.$router);
    jest.spyOn(store.$router, 'push');
    routerPush({ name: 'dashboard', query });
    expect(store.dispatch).toHaveBeenCalledWith(`vulnerabilities/setVulnerabilitiesPage`, 1);
  });

  it("doesn't update the store if the URL update originated from the mediator", () => {
    const query = { example: ['test'] };

    jest.spyOn(store, 'commit').mockImplementation(noop);

    store.$router.push({ name: 'dashboard', query, params: { updatedFromState: true } });

    expect(store.commit).toHaveBeenCalledTimes(0);
  });

  it('it updates the route after a successful vulnerability retrieval', () => {
    const activeFilters = store.getters['filters/activeFilters'];
    const page = 2;

    jest.spyOn(store.$router, 'push').mockImplementation(noop);

    store.dispatch(`vulnerabilities/fetchVulnerabilities`, { page });

    expect(store.$router.push).toHaveBeenCalledTimes(1);
    expect(store.$router.push).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'dashboard',
        query: expect.objectContaining({
          ...activeFilters,
          page,
          days: store.state.vulnerabilities.vulnerabilitiesHistoryDayRange,
        }),
        params: { updatedFromState: true },
      }),
    );
  });

  it('it updates the route after changing the vulnerability history day range', () => {
    const activeFilters = store.getters['filters/activeFilters'];
    const days = DAYS.SIXTY;

    jest.spyOn(store.$router, 'push').mockImplementation(noop);

    store.dispatch(`vulnerabilities/setVulnerabilitiesHistoryDayRange`, days);

    expect(store.$router.push).toHaveBeenCalledTimes(1);
    expect(store.$router.push).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'dashboard',
        query: expect.objectContaining({
          ...activeFilters,
          page: store.state.vulnerabilities.pageInfo.page,
          days,
        }),
        params: { updatedFromState: true },
      }),
    );
  });
});
