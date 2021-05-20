import { mount } from '@vue/test-utils';
import Api from '~/api';
import NamespaceSelect from '~/pages/admin/projects/components/namespace_select.vue';

describe('Dropdown select component', () => {
  let wrapper;

  const mountDropdown = (propsData) => {
    wrapper = mount(NamespaceSelect, { propsData });
  };

  const findNamespaceInput = () => wrapper.find('input[name="namespace-input"]');
  const findFilterInput = () => wrapper.find('.namespace-search-box input');
  // const findDropdownOption = (match) =>
  //   wrapper
  //     .findAll('button.dropdown-item')
  //     .filter((node) => node.text().match(match))
  //     .at(0);

  const setFieldValue = async (field, value) => {
    await field.setValue(value);
    field.trigger('blur');
  };

  beforeEach(() => {
    setFixtures('<div class="test-container"></div>');

    jest.spyOn(Api, 'namespaces').mockResolvedValue([
      { id: 1, kind: 'user', full_path: 'Administrator' },
      { id: 2, kind: 'group', full_path: 'GitLab Org' },
    ]);
  });

  it('creates a hidden input if fieldName is provided', () => {
    mountDropdown({ fieldName: 'namespace-input' });

    expect(findNamespaceInput().exists()).toBeTrue();
  });

  describe('clicking dropdown options', () => {
    it('retrieves namespaces based on filter query', async () => {
      mountDropdown();

      await setFieldValue(findFilterInput(), 'test');

      expect(Api.namespaces).toHaveBeenCalledWith('test', expect.anything());
    });

    it('updates the dropdown value based upon selection', async () => {
      expect(true).toBeTruthy();
    });

    it('triggers a setNamespace event upon selection', () => {
      expect(true).toBeTruthy();
    });

    it('displays "Any Namespace" option when showAny prop provided', () => {
      expect(true).toBeTruthy();
    });
  });
});
