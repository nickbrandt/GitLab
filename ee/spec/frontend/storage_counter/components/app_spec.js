import { mount } from '@vue/test-utils';
import StorageApp from 'ee/storage_counter/components/app.vue';
import Project from 'ee/storage_counter/components/project.vue';
import { projects, withRootStorageStatistics } from '../data';
import { numberToHumanSize } from '~/lib/utils/number_utils';

describe('Storage counter app', () => {
  let wrapper;

  const findTotalUsage = () => wrapper.find("[data-testid='total-usage']");
  const findPurchaseStorageLink = () => wrapper.find("[data-testid='purchase-storage-link']");

  function createComponent(props = {}, loading = false) {
    const $apollo = {
      queries: {
        namespace: {
          loading,
        },
      },
    };

    wrapper = mount(StorageApp, {
      propsData: { namespacePath: 'h5bp', helpPagePath: 'help', ...props },
      mocks: { $apollo },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the 2 projects', async () => {
    wrapper.setData({
      namespace: projects,
    });

    await wrapper.vm.$nextTick();

    expect(wrapper.findAll(Project)).toHaveLength(2);
  });

  describe('limit', () => {
    it('when limit is set it renders limit information', async () => {
      wrapper.setData({
        namespace: projects,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toContain(numberToHumanSize(projects.limit));
    });

    it('when limit is 0 it does not render limit information', async () => {
      wrapper.setData({
        namespace: { ...projects, limit: 0 },
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.text()).not.toContain(numberToHumanSize(0));
    });
  });

  describe('with rootStorageStatistics information', () => {
    it('renders total usage', async () => {
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      await wrapper.vm.$nextTick();

      expect(findTotalUsage().text()).toContain(withRootStorageStatistics.totalUsage);
    });
  });

  describe('without rootStorageStatistics information', () => {
    it('renders N/A', async () => {
      wrapper.setData({
        namespace: projects,
      });

      await wrapper.vm.$nextTick();

      expect(findTotalUsage().text()).toContain('N/A');
    });
  });

  describe('purchase storage link', () => {
    describe('when purchaseStorageUrl is not set', () => {
      it('does not render an additional link', () => {
        expect(findPurchaseStorageLink().exists()).toBe(false);
      });
    });

    describe('when purchaseStorageUrl is set', () => {
      beforeEach(() => {
        createComponent({ purchaseStorageUrl: 'customers.gitlab.com' });
      });

      it('does render link', () => {
        const link = findPurchaseStorageLink();

        expect(link).toExist();
        expect(link.attributes('href')).toBe('customers.gitlab.com');
      });
    });
  });
});
