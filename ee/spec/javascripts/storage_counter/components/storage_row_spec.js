import { shallowMount, createLocalVue } from '@vue/test-utils';
import StorageRow from 'ee/storage_counter/components/storage_row.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

let wrapper;
const data = {
  name: 'LFS Package',
  value: 1293346,
};
const localVue = createLocalVue();

function factory({ name, value }) {
  wrapper = shallowMount(localVue.extend(StorageRow), {
    propsData: {
      name,
      value,
    },
    localVue,
    sync: false,
  });
}

describe('Storage Counter row component', () => {
  beforeEach(() => {
    factory(data);
  });

  it('renders provided name', () => {
    expect(wrapper.text()).toContain(data.name);
  });

  it('renders formatted value', () => {
    expect(wrapper.text()).toContain(numberToHumanSize(data.value));
  });
});
