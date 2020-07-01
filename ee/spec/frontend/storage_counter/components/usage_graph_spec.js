import { shallowMount } from '@vue/test-utils';
import UsageGraph from 'ee/storage_counter/components/usage_graph.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

let data;
let wrapper;

function mountComponent({ rootStorageStatistics, limit }) {
  wrapper = shallowMount(UsageGraph, {
    propsData: {
      rootStorageStatistics,
      limit,
    },
  });
}
function findStorageTypeUsagesSerialized() {
  return wrapper
    .findAll('[data-testid="storage-type-usage"]')
    .wrappers.map(wp => wp.element.style.flex);
}

describe('Storage Counter usage graph component', () => {
  beforeEach(() => {
    data = {
      rootStorageStatistics: {
        wikiSize: 5000,
        repositorySize: 4000,
        packagesSize: 3000,
        lfsObjectsSize: 2000,
        buildArtifactsSize: 1000,
        storageSize: 15000,
      },
      limit: 2000,
    };
    mountComponent(data);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the legend in order', () => {
    const types = wrapper.findAll('[data-testid="storage-type-legend"]');

    const {
      buildArtifactsSize,
      lfsObjectsSize,
      packagesSize,
      repositorySize,
      wikiSize,
    } = data.rootStorageStatistics;

    expect(types.at(0).text()).toMatchInterpolatedText(`Wikis ${numberToHumanSize(wikiSize)}`);
    expect(types.at(1).text()).toMatchInterpolatedText(
      `Repositories ${numberToHumanSize(repositorySize)}`,
    );
    expect(types.at(2).text()).toMatchInterpolatedText(
      `Packages ${numberToHumanSize(packagesSize)}`,
    );
    expect(types.at(3).text()).toMatchInterpolatedText(
      `LFS Objects ${numberToHumanSize(lfsObjectsSize)}`,
    );
    expect(types.at(4).text()).toMatchInterpolatedText(
      `Build Artifacts ${numberToHumanSize(buildArtifactsSize)}`,
    );
  });

  describe('when storage type is not used', () => {
    beforeEach(() => {
      data.rootStorageStatistics.wikiSize = 0;
      mountComponent(data);
    });

    it('filters the storage type', () => {
      expect(wrapper.text()).not.toContain('Wikis');
    });
  });

  describe('when there is no storage usage', () => {
    beforeEach(() => {
      data.rootStorageStatistics.storageSize = 0;
      mountComponent(data);
    });

    it('it does not render', () => {
      expect(wrapper.html()).toEqual('');
    });
  });

  describe('when limit is 0', () => {
    beforeEach(() => {
      data.limit = 0;
      mountComponent(data);
    });

    it('sets correct flex values', () => {
      expect(findStorageTypeUsagesSerialized()).toStrictEqual([
        '0.3333333333333333',
        '0.26666666666666666',
        '0.2',
        '0.13333333333333333',
        '0.06666666666666667',
      ]);
    });
  });

  describe('when storage exceeds limit', () => {
    beforeEach(() => {
      data.limit = data.rootStorageStatistics.storageSize - 1;
      mountComponent(data);
    });

    it('it does render correclty', () => {
      expect(findStorageTypeUsagesSerialized()).toStrictEqual([
        '0.3333333333333333',
        '0.26666666666666666',
        '0.2',
        '0.13333333333333333',
        '0.06666666666666667',
      ]);
    });
  });
});
