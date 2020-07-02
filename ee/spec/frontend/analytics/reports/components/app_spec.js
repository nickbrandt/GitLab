import ReportsApp from 'ee/analytics/reports/components/app.vue';
import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import { objectToQuery } from '~/lib/utils/url_utility';

const GROUP_NAME = 'Gitlab Org';
const GROUP_PATH = 'gitlab-org';
const DEFAULT_REPORT_TITLE = 'Report';

const GROUP_URL_QUERY = objectToQuery({
  groupName: GROUP_NAME,
  groupPath: GROUP_PATH,
});

describe('ReportsApp', () => {
  let wrapper;

  const createComponent = () => {
    return shallowMount(ReportsApp);
  };

  const findGlBreadcrumb = () => wrapper.find(GlBreadcrumb);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('contains the correct breadcrumbs', () => {
    it('displays the report title by default', () => {
      wrapper = createComponent();

      const breadcrumbs = findGlBreadcrumb();

      expect(breadcrumbs.props('items')).toStrictEqual([{ text: DEFAULT_REPORT_TITLE, href: '' }]);
    });

    describe('with a group in the URL', () => {
      beforeEach(() => {
        window.history.replaceState({}, null, `?${GROUP_URL_QUERY}`);
      });

      it('displays the group name and report title', () => {
        wrapper = createComponent();

        const breadcrumbs = findGlBreadcrumb();

        expect(breadcrumbs.props('items')).toStrictEqual([
          { text: GROUP_NAME, href: `/${GROUP_PATH}` },
          { text: DEFAULT_REPORT_TITLE, href: '' },
        ]);
      });
    });
  });
});
