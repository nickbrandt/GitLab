import { mount } from '@vue/test-utils';
import $ from 'jquery';
import 'bootstrap';
import '~/gl_dropdown';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import Api from '~/api';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('~/api', () => ({
  groups: jest.fn(),
}));

const groups = [
  {
    id: 1,
    name: 'foo',
    avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
  },
  {
    id: 2,
    name: 'foobar',
    avatar_url: null,
  },
];

describe('GroupsDropdownFilter component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    jest.spyOn($.fn, 'glDropdown');
    Api.groups.mockImplementation((term, options, callback) => {
      callback(groups);
    });
    wrapper = mount(GroupsDropdownFilter);
  });

  const findDropdown = () => wrapper.find('.dropdown');
  const openDropdown = () => {
    $(findDropdown().element)
      .parent()
      .trigger('shown.bs.dropdown');
  };
  const findDropdownItems = () => findDropdown().findAll('a');
  const findDropdownButton = () => findDropdown().find('button');

  it('should call glDropdown', () => {
    expect($.fn.glDropdown).toHaveBeenCalled();
  });

  describe('it renders the items correctly', () => {
    beforeEach(() => {
      openDropdown();

      return wrapper.vm.$nextTick();
    });

    it('should contain 2 items', () => {
      expect(findDropdownItems().length).toEqual(2);
    });

    it('renders an avatar when the group has an avatar_url', () => {
      expect(
        findDropdownItems()
          .at(0)
          .contains('img.avatar'),
      ).toBe(true);
      expect(
        findDropdownItems()
          .at(0)
          .contains('div.identicon'),
      ).toBe(false);
    });

    it("renders an identicon when the group doesn't have an avatar_url", () => {
      expect(
        findDropdownItems()
          .at(1)
          .contains('img.avatar'),
      ).toBe(false);
      expect(
        findDropdownItems()
          .at(1)
          .contains('div.identicon'),
      ).toBe(true);
    });
  });

  describe('on group click', () => {
    beforeEach(() => {
      openDropdown();

      return wrapper.vm.$nextTick();
    });

    it('should emit the "selected" event with the selected group', () => {
      findDropdownItems()
        .at(0)
        .trigger('click');

      expect(wrapper.emittedByOrder()).toEqual([
        {
          name: 'selected',
          args: [groups[0]],
        },
      ]);
    });

    it('should change selection when new group is clicked', () => {
      findDropdownItems()
        .at(1)
        .trigger('click');

      expect(wrapper.emittedByOrder()).toEqual([
        {
          name: 'selected',
          args: [groups[1]],
        },
      ]);
    });

    it('renders an avatar in the dropdown button when the group has an avatar_url', done => {
      findDropdownItems()
        .at(0)
        .trigger('click');

      wrapper.vm.$nextTick(() => {
        expect(findDropdownButton().contains('img.avatar')).toBe(true);
        expect(findDropdownButton().contains('div.identicon')).toBe(false);
        done();
      });
    });

    it("renders an identicon in the dropdown button when the group doesn't have an avatar_url", done => {
      findDropdownItems()
        .at(1)
        .trigger('click');

      wrapper.vm.$nextTick(() => {
        expect(findDropdownButton().contains('img.avatar')).toBe(false);
        expect(findDropdownButton().contains('div.identicon')).toBe(true);
        done();
      });
    });
  });
});
