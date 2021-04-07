import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ListItem from 'ee/groups/settings/compliance_frameworks/components/list_item.vue';
import {
  DELETE_BUTTON_LABEL,
  EDIT_BUTTON_LABEL,
} from 'ee/groups/settings/compliance_frameworks/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('ListItem', () => {
  let wrapper;

  const framework = {
    parsedId: 1,
    name: 'framework',
    description: 'a framework',
    color: '#112233',
    editPath: 'group/framework/1/edit',
  };

  const findLabel = () => wrapper.findComponent(GlLabel);
  const findDescription = () => wrapper.findByTestId('compliance-framework-description');
  const findEditButton = () => wrapper.findByTestId('compliance-framework-edit-button');
  const findDeleteButton = () => wrapper.findByTestId('compliance-framework-delete-button');

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ListItem, {
        propsData: {
          framework,
          loading: false,
          ...props,
        },
        directives: {
          GlTooltip: createMockDirective(),
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const displaysTheButton = (button, icon, ariaLabel) => {
    expect(button.props('icon')).toBe(icon);
    expect(button.props('disabled')).toBe(false);
    expect(button.props('loading')).toBe(false);
    expect(button.attributes('aria-label')).toBe(ariaLabel);
  };

  it('does not show modification buttons when framework is missing paths', () => {
    createComponent({
      framework: { ...framework, editPath: null },
    });

    expect(findEditButton().exists()).toBe(false);
    expect(findDeleteButton().exists()).toBe(false);
  });

  it('displays the description defined by the framework', () => {
    createComponent();

    expect(findDescription().text()).toBe('a framework');
  });

  it('displays the label as unscoped', () => {
    createComponent();

    expect(findLabel().props('title')).toBe('framework');
    expect(findLabel().props('target')).toBe(framework.editPath);
    expect(findLabel().props('scoped')).toBe(false);
  });

  it('displays the label as scoped', () => {
    createComponent({
      framework: { ...framework, name: 'scoped::framework' },
    });

    expect(findLabel().props('title')).toBe('scoped::framework');
    expect(findLabel().props('target')).toBe(framework.editPath);
    expect(findLabel().props('scoped')).toBe(true);
    expect(findLabel().props('disabled')).toBe(false);
  });

  it('displays the edit button', () => {
    createComponent();

    const button = findEditButton();

    displaysTheButton(button, 'pencil', EDIT_BUTTON_LABEL);
    expect(button.attributes('href')).toBe('group/framework/1/edit');
  });

  it('displays a delete button', () => {
    createComponent();

    const button = findDeleteButton();
    const tooltip = getBinding(button.element, 'gl-tooltip');

    displaysTheButton(button, 'remove', DELETE_BUTTON_LABEL);
    expect(tooltip.value).toBe('Delete framework');
  });

  it('emits "delete" event when the delete button is clicked', async () => {
    createComponent();

    findDeleteButton().vm.$emit('click');

    expect(wrapper.emitted('delete')[0]).toStrictEqual([framework]);
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('disables the label', () => {
      expect(findLabel().props('disabled')).toBe(true);
    });

    it('disables the delete button and shows loading', () => {
      const button = findDeleteButton();

      expect(button.props('disabled')).toBe(true);
      expect(button.props('loading')).toBe(true);
    });

    it('disables the edit button and does not show loading', () => {
      const button = findEditButton();

      expect(button.props('disabled')).toBe(true);
      expect(button.props('loading')).toBe(false);
    });
  });
});
