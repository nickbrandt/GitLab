import { shallowMount } from '@vue/test-utils';
import StorageInlineAlert from 'ee/storage_counter/components/storage_inline_alert.vue';
import { GlAlert } from '@gitlab/ui';

const THIRTEEN_GB_IN_BYTES = 1.3e10;
const TEN_GB_IN_BYTES = 1e10;
const FIVE_GB_IN_BYTES = 5e9;
const THREE_GB_IN_BYTES = 3e9;

describe('StorageInlineAlert', () => {
  let wrapper;

  function mountComponent(props) {
    wrapper = shallowMount(StorageInlineAlert, {
      propsData: props,
    });
  }

  const findAlert = () => wrapper.find(GlAlert);

  describe('no excess storage and no purchase', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: false,
        repositorySizeExcessProjectCount: 0,
        totalRepositorySizeExcess: 0,
        totalRepositorySize: FIVE_GB_IN_BYTES,
        additionalPurchasedStorageSize: 0,
        repositoryFreeSizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('does not render an alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('excess storage and no purchase', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: true,
        repositorySizeExcessProjectCount: 1,
        totalRepositorySizeExcess: THREE_GB_IN_BYTES,
        totalRepositorySize: THIRTEEN_GB_IN_BYTES,
        additionalPurchasedStorageSize: 0,
        repositoryFreeSizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('renders danger variant alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
    });

    it('renders human readable repositoryFreeLimit', () => {
      // Note how we get a less good looking 9.31 GiB number
      // Will be fixed in https://gitlab.com/gitlab-org/gitlab/-/issues/263284
      expect(findAlert().text()).toBe(
        'You have reached the free storage limit of 9.31 GiB on 1 project. To unlock them, please purchase additional storage.',
      );
    });
  });

  describe('excess storage below purchase limit', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: false,
        repositorySizeExcessProjectCount: 0,
        totalRepositorySizeExcess: THREE_GB_IN_BYTES,
        totalRepositorySize: THIRTEEN_GB_IN_BYTES,
        additionalPurchasedStorageSize: FIVE_GB_IN_BYTES,
        repositoryFreeSizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('renders info variant alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('info');
    });

    it('renders text explaining storage', () => {
      expect(findAlert().text()).toBe(
        'When you purchase additional storage, we automatically unlock projects that were locked when you reached the 9.31 GiB limit.',
      );
    });
  });

  describe('excess storage above purchase limit', () => {
    beforeEach(() => {
      mountComponent({
        containsLockedProjects: true,
        repositorySizeExcessProjectCount: 1,
        totalRepositorySizeExcess: THREE_GB_IN_BYTES,
        totalRepositorySize: THIRTEEN_GB_IN_BYTES,
        additionalPurchasedStorageSize: THREE_GB_IN_BYTES,
        repositoryFreeSizeLimit: TEN_GB_IN_BYTES,
      });
    });

    it('renders danger alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
    });
  });
});
