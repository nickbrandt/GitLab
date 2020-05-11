import { shallowMount } from '@vue/test-utils';
import UsageGraph from 'ee/storage_counter/components/usage_graph.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

const data = {
  wikiSize: 5000,
  repositorySize: 4000,
  packagesSize: 3000,
  lfsObjectsSize: 2000,
  buildArtifactsSize: 1000,
  storageSize: 15000,
};

let wrapper;
function mountComponent(rootStorageStatistics) {
  wrapper = shallowMount(UsageGraph, {
    propsData: {
      rootStorageStatistics,
    },
  });
}

describe('Storage Counter usage graph component', () => {
  beforeEach(() => {
    mountComponent(data);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the legend in order', () => {
    const types = wrapper.findAll('[data-testid="storage-type"]');

    expect(types.at(0).text()).toContain('Wikis');
    expect(types.at(1).text()).toContain('Repositories');
    expect(types.at(2).text()).toContain('Packages');
    expect(types.at(3).text()).toContain('LFS Objects');
    expect(types.at(4).text()).toContain('Build Artifacts');
  });

  it('renders formatted data in the legend', () => {
    expect(wrapper.text()).toContain(numberToHumanSize(data.buildArtifactsSize));
    expect(wrapper.text()).toContain(numberToHumanSize(data.lfsObjectsSize));
    expect(wrapper.text()).toContain(numberToHumanSize(data.packagesSize));
    expect(wrapper.text()).toContain(numberToHumanSize(data.repositorySize));
    expect(wrapper.text()).toContain(numberToHumanSize(data.wikiSize));
  });

  describe('when storage type is not used', () => {
    beforeEach(() => {
      data.wikiSize = 0;
      mountComponent(data);
    });

    it('filters the storage type', () => {
      expect(wrapper.text()).not.toContain('Wikis');
    });
  });

  describe('when there is no storage usage', () => {
    beforeEach(() => {
      mountComponent({ storageSize: 0 });
    });

    it('it does not render', () => {
      expect(wrapper.html()).toEqual('');
    });
  });
});
