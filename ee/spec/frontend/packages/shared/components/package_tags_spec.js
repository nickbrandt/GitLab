import { mount } from '@vue/test-utils';
import PackageTags from 'ee/packages/shared/components/package_tags.vue';
import { mockTags } from '../../mock_data';

describe('PackageTags', () => {
  let wrapper;

  function createComponent(tags = [], props = {}) {
    const propsData = {
      tags,
      ...props,
    };

    wrapper = mount(PackageTags, {
      propsData,
    });
  }

  const tagLabel = () => wrapper.find({ ref: 'tagLabel' });
  const tagBadges = () => wrapper.findAll({ ref: 'tagBadge' });
  const moreBadge = () => wrapper.find({ ref: 'moreBadge' });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  describe('tag label', () => {
    it('shows the tag label by default', () => {
      createComponent();

      expect(tagLabel().exists()).toBe(true);
    });

    it('hides when hideLabel prop is set to true', () => {
      createComponent(mockTags, { hideLabel: true });

      expect(tagLabel().exists()).toBe(false);
    });
  });

  it('renders the correct number of tags', () => {
    createComponent(mockTags.slice(0, 2));

    expect(tagBadges()).toHaveLength(2);
    expect(moreBadge().exists()).toBe(false);
  });

  it('does not render more than the configured tagDisplayLimit', () => {
    createComponent(mockTags);

    expect(tagBadges()).toHaveLength(2);
  });

  it('renders the more tags badge if there are more than the configured limit', () => {
    createComponent(mockTags);

    expect(tagBadges()).toHaveLength(2);
    expect(moreBadge().exists()).toBe(true);
    expect(moreBadge().text()).toContain('2');
  });

  it('renders the configured tagDisplayLimit when set in props', () => {
    createComponent(mockTags, { tagDisplayLimit: 1 });

    expect(tagBadges()).toHaveLength(1);
    expect(moreBadge().exists()).toBe(true);
    expect(moreBadge().text()).toContain('3');
  });

  describe('tagBadgeStyle', () => {
    const defaultStyle = {
      'd-none': true,
      'd-block': false,
      'd-md-block': false,
      'append-right-4': false,
    };

    it('shows tag badge when there is only one', () => {
      createComponent([mockTags[0]]);

      const expectedStyle = {
        ...defaultStyle,
        'd-block': true,
      };

      expect(wrapper.vm.tagBadgeClass(0)).toEqual(expectedStyle);
    });

    it('shows tag badge for medium or heigher resolutions', () => {
      createComponent(mockTags);

      const expectedStyle = {
        ...defaultStyle,
        'd-md-block': true,
      };

      expect(wrapper.vm.tagBadgeClass(1)).toEqual(expectedStyle);
    });

    it('correctly appends right when there is more than one tag', () => {
      createComponent(mockTags, {
        tagDisplayLimit: 4,
      });

      const expectedStyleWithoutAppend = {
        ...defaultStyle,
        'd-md-block': true,
      };

      const expectedStyleWithAppend = {
        ...expectedStyleWithoutAppend,
        'append-right-4': true,
      };

      expect(wrapper.vm.tagBadgeClass(0)).toEqual(expectedStyleWithAppend);
      expect(wrapper.vm.tagBadgeClass(1)).toEqual(expectedStyleWithAppend);
      expect(wrapper.vm.tagBadgeClass(2)).toEqual(expectedStyleWithAppend);
      expect(wrapper.vm.tagBadgeClass(3)).toEqual(expectedStyleWithoutAppend);
    });
  });
});
