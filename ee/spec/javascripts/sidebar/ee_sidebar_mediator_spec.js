import SidebarMediator from 'ee/sidebar/sidebar_mediator';
import CESidebarMediator from '~/sidebar/sidebar_mediator';
import CESidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './ee_mock_data';

describe('EE Sidebar mediator', () => {
  let mediator;

  beforeEach(() => {
    mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    SidebarService.singleton = null;
    CESidebarStore.singleton = null;
    CESidebarMediator.singleton = null;
  });

  it('processes fetched data', () => {
    const mockData =
      Mock.responseMap.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar'];
    mediator.processFetchedData(mockData);

    expect(mediator.store.weight).toEqual(mockData.weight);
  });
});
