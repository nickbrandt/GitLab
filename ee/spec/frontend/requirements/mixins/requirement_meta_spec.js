import { shallowMount } from '@vue/test-utils';

import RequirementItem from 'ee/requirements/components/requirement_item.vue';
import { FilterState } from 'ee/requirements/constants';

import { mockAuthor, mockTestReport, requirement1 as mockRequirement } from '../mock_data';

const createComponent = (requirement = mockRequirement) =>
  shallowMount(RequirementItem, {
    propsData: {
      requirement,
    },
  });

describe('RequirementMeta Mixin', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('reference', () => {
      it('returns string containing `requirement.iid` prefixed with `REQ-`', () => {
        expect(wrapper.vm.reference).toBe(`REQ-${mockRequirement.iid}`);
      });
    });

    describe('titleHtml', () => {
      it('returns value of `requirement.titleHtml`', () => {
        expect(wrapper.vm.titleHtml).toBe(mockRequirement.titleHtml);
      });
    });

    describe('descriptionHtml', () => {
      it('returns value of `requirement.descriptionHtml`', () => {
        expect(wrapper.vm.descriptionHtml).toBe(mockRequirement.descriptionHtml);
      });
    });

    describe('isClosed', () => {
      it('returns true when `requirement.state` is "CLOSED"', async () => {
        wrapper.setProps({
          requirement: {
            ...mockRequirement,
            state: FilterState.closed,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.isClosed).toBe(true);
      });

      it('returns false when `requirement.state` is "OPENED"', () => {
        expect(wrapper.vm.isClosed).toBe(false);
      });
    });

    describe('author', () => {
      it('returns value of `requirement.author`', () => {
        expect(wrapper.vm.author).toBe(mockAuthor);
      });
    });

    describe('createdAtFormatted', () => {
      it('returns timeago-style string representing `requirement.createdAtFormatted`', () => {
        // We don't have to be accurate here as it is already covered in rspecs
        expect(wrapper.vm.createdAtFormatted).toContain('created');
        expect(wrapper.vm.createdAtFormatted).toContain('ago');
      });
    });

    describe('updatedAtFormatted', () => {
      it('returns timeago-style string representing `requirement.updatedAtFormatted`', () => {
        // We don't have to be accurate here as it is already covered in rspecs
        expect(wrapper.vm.updatedAtFormatted).toContain('updated');
        expect(wrapper.vm.updatedAtFormatted).toContain('ago');
      });
    });

    describe('testReport', () => {
      it('returns testReport object from reports array within `requirement`', () => {
        expect(wrapper.vm.testReport).toBe(mockTestReport);
      });
    });

    describe('canUpdate', () => {
      it('returns value of `requirement.userPermissions.updateRequirement`', () => {
        expect(wrapper.vm.canUpdate).toBe(mockRequirement.userPermissions.updateRequirement);
      });
    });

    describe('canClose', () => {
      it('returns value of `requirement.userPermissions.updateRequirement`', () => {
        expect(wrapper.vm.canClose).toBe(mockRequirement.userPermissions.adminRequirement);
      });
    });
  });
});
