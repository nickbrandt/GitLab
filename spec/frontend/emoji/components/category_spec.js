import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Category from '~/emoji/components/category.vue';
import EmojiGroup from '~/emoji/components/emoji_group.vue';

let wrapper;
function factory(propsData = {}) {
  wrapper = shallowMount(Category, { propsData });
}

describe('Emoji category component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders emoji groups', () => {
    factory({
      category: 'Activity',
      emojis: [['thumbsup'], ['thumbsdown']],
    });

    expect(wrapper.findAll(EmojiGroup).length).toBe(2);
  });

  it('renders group', async () => {
    factory({
      category: 'Activity',
      emojis: [['thumbsup'], ['thumbsdown']],
    });

    await wrapper.setData({ renderGroup: true });

    expect(wrapper.find(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('renders group on appear', async () => {
    factory({
      category: 'Activity',
      emojis: [['thumbsup'], ['thumbsdown']],
    });

    wrapper.find(GlIntersectionObserver).vm.$emit('appear');

    await nextTick();

    expect(wrapper.find(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('emits appear event on appear', async () => {
    factory({
      category: 'Activity',
      emojis: [['thumbsup'], ['thumbsdown']],
    });

    wrapper.find(GlIntersectionObserver).vm.$emit('appear');

    await nextTick();

    expect(wrapper.emitted().appear[0]).toEqual(['Activity']);
  });
});
