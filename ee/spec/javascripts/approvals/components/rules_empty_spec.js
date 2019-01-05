import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import RulesEmpty from 'ee/approvals/components/rules_empty.vue';

const localVue = createLocalVue();

describe('EE ApprovalsSettingsEmpty', () => {
  let wrapper;

  const factory = options => {
    wrapper = shallowMount(localVue.extend(RulesEmpty), {
      localVue,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows message', () => {
    factory();

    expect(wrapper.text()).toContain(RulesEmpty.message);
  });

  it('shows button', () => {
    factory();

    expect(wrapper.find(GlButton).exists()).toBe(true);
  });

  it('emits "click" on button press', () => {
    factory();

    expect(wrapper.emittedByOrder().length).toEqual(0);

    wrapper.find(GlButton).vm.$emit('click');

    expect(wrapper.emittedByOrder().map(x => x.name)).toEqual(['click']);
  });
});
