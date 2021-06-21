import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Commit from 'ee/vulnerabilities/components/generic_report/types/commit.vue';

const TEST_DATA = {
  value: '24922148',
};
const TEST_PROJECT_COMMIT_PATH = '/foo/bar';

describe('ee/vulnerabilities/components/generic_report/types/commit.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMount(Commit, {
      propsData: TEST_DATA,
      provide: {
        projectCommitPath: TEST_PROJECT_COMMIT_PATH,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('links to the given commit hash', () => {
    expect(findLink().attributes('href')).toBe(`${TEST_PROJECT_COMMIT_PATH}/${TEST_DATA.value}`);
  });

  it('shows the value as the link-text', () => {
    wrapper = createWrapper();

    expect(findLink().text()).toBe(TEST_DATA.value);
  });
});
