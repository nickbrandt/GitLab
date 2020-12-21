import jQuery from 'jquery';
import waitForPromises from 'helpers/wait_for_promises';
import { expandSection, closeSection } from '~/settings_panels';
import initSearch from '~/search_settings';
import mountSearchSettings from '~/pages/projects/edit/mount_search_settings';

jest.mock('~/settings_panels', () => {
  return {
    expandSection: jest.fn(),
    closeSection: jest.fn(),
  };
});

jest.mock('~/search_settings', () => {
  return jest.fn();
});

describe('pages/projects/edit/mount_search_settings', () => {
  beforeEach(() => {
    window.gon.features = { searchSettingsInPage: true };
  });

  afterEach(() => {
    initSearch.mockReset();
  });

  it('does not initialize search settings when feature flag is off', async () => {
    window.gon.features.searchSettingsInPage = false;
    mountSearchSettings();

    await waitForPromises();

    expect(initSearch).not.toHaveBeenCalled();
  });

  it('calls settingPanels.expandSection when onExpand is invoked', async () => {
    const section = document.createElement('div');

    mountSearchSettings();

    await waitForPromises();

    const initParams = initSearch.mock.calls[0][0];

    initParams.onExpand(section);

    expect(expandSection).toHaveBeenCalled();
    expect(expandSection.mock.calls[0][0]).toBeInstanceOf(jQuery);
    expect(expandSection.mock.calls[0][0].get(0)).toBe(section);
  });

  it('calls settingPanels.closeSection when onCollapse is invoked', async () => {
    const section = document.createElement('div');

    mountSearchSettings();

    await waitForPromises();

    const initParams = initSearch.mock.calls[0][0];

    initParams.onCollapse(section);

    expect(closeSection).toHaveBeenCalled();
    expect(closeSection.mock.calls[0][0]).toBeInstanceOf(jQuery);
    expect(closeSection.mock.calls[0][0].get(0)).toBe(section);
  });
});
