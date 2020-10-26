import { GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineStatusBadge from 'ee/security_dashboard/components/pipeline_status_badge.vue';

describe('Pipeline status badge', () => {
  let wrapper;

  const securityBuildsFailedPath = '/some/path/to/failed/jobs';
  const DEFAULT_PROPS = {
    pipeline: {
      securityBuildsFailedCount: 5,
      securityBuildsFailedPath,
    },
  };

  const findGlBadge = () => wrapper.find(GlBadge);
  const findGlIcon = () => wrapper.find(GlIcon);

  const createProps = securityBuildsFailedCount => ({ pipeline: { securityBuildsFailedCount } });

  const createWrapper = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineStatusBadge, {
      propsData: { ...DEFAULT_PROPS, ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there are more than 0 failed jobs', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays correct message for 5 failed jobs', () => {
      expect(wrapper.text()).toBe('5 failed security jobs');
    });

    it('links to the correct path', () => {
      expect(findGlBadge().attributes('href')).toBe(securityBuildsFailedPath);
    });

    it('displays correct message for 1 failed job', () => {
      createWrapper({ props: createProps(1) });
      expect(wrapper.text()).toBe('1 failed security job');
    });
  });

  describe('when there are not more than 0 failed jobs', () => {
    it('does not display when there are 0 failed jobs', () => {
      createWrapper({ props: createProps(0) });
      expect(findGlBadge().exists()).toBe(false);
      expect(findGlIcon().exists()).toBe(false);
    });

    it('does not display when there is no failed jobs count', () => {
      createWrapper({ props: createProps(undefined) });
      expect(findGlBadge().exists()).toBe(false);
      expect(findGlIcon().exists()).toBe(false);
    });
  });
});
