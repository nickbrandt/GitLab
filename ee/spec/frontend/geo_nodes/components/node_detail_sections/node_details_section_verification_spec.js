import { shallowMount } from '@vue/test-utils';
import { GlPopover, GlSprintf } from '@gitlab/ui';

import NodeDetailsSectionVerificationComponent from 'ee/geo_nodes/components/node_detail_sections/node_details_section_verification.vue';
import SectionRevealButton from 'ee/geo_nodes/components/node_detail_sections/section_reveal_button.vue';

import { mockNodeDetails } from '../../mock_data';

describe('NodeDetailsSectionVerification', () => {
  let wrapper;

  const defaultProps = {
    nodeDetails: mockNodeDetails,
    nodeTypePrimary: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NodeDetailsSectionVerificationComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlPopover = () => wrapper.find(GlPopover);

  describe('data', () => {
    it('returns default data props', () => {
      expect(wrapper.vm.showSectionItems).toBe(false);
      expect(Array.isArray(wrapper.vm.primaryNodeDetailItems)).toBe(true);
      expect(Array.isArray(wrapper.vm.secondaryNodeDetailItems)).toBe(true);
      expect(wrapper.vm.primaryNodeDetailItems.length).toBeGreaterThan(0);
      expect(wrapper.vm.secondaryNodeDetailItems.length).toBeGreaterThan(0);
    });
  });

  describe('methods', () => {
    describe('getPrimaryNodeDetailItems', () => {
      const primaryItems = [
        {
          title: 'Repository checksum progress',
          valueProp: 'repositoriesChecksummed',
        },
        {
          title: 'Wiki checksum progress',
          valueProp: 'wikisChecksummed',
        },
      ];

      it('returns array containing items to show under primary node', () => {
        const actualPrimaryItems = wrapper.vm.getPrimaryNodeDetailItems();
        primaryItems.forEach((item, index) => {
          expect(actualPrimaryItems[index].itemTitle).toBe(item.title);
          expect(actualPrimaryItems[index].itemValue).toBe(mockNodeDetails[item.valueProp]);
        });
      });
    });

    describe('getSecondaryNodeDetailItems', () => {
      const secondaryItems = [
        {
          title: 'Repository verification progress',
          valueProp: 'verifiedRepositories',
        },
        {
          title: 'Wiki verification progress',
          valueProp: 'verifiedWikis',
        },
      ];

      it('returns array containing items to show under secondary node', () => {
        const actualSecondaryItems = wrapper.vm.getSecondaryNodeDetailItems();
        secondaryItems.forEach((item, index) => {
          expect(actualSecondaryItems[index].itemTitle).toBe(item.title);
          expect(actualSecondaryItems[index].itemValue).toBe(mockNodeDetails[item.valueProp]);
        });
      });
    });
  });

  describe('computed', () => {
    describe('nodeText', () => {
      describe('on Primary node', () => {
        beforeEach(() => {
          createComponent({ nodeTypePrimary: true });
        });

        it('returns text about secondary nodes', () => {
          expect(wrapper.vm.nodeText).toBe('secondary nodes');
        });
      });

      describe('on Secondary node', () => {
        beforeEach(() => {
          createComponent();
        });

        it('returns text about secondary nodes', () => {
          expect(wrapper.vm.nodeText).toBe('primary node');
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(wrapper.vm.$el.classList.contains('verification-section')).toBe(true);
    });

    it('renders show section button element', () => {
      expect(wrapper.find(SectionRevealButton).exists()).toBeTruthy();
      expect(wrapper.find(SectionRevealButton).attributes('buttontitle')).toBe(
        'Verification information',
      );
    });

    it('renders section items container element', () => {
      wrapper.vm.showSectionItems = true;
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.$el.querySelector('.section-items-container')).not.toBeNull();
      });
    });

    describe('GlPopover', () => {
      it('renders always', () => {
        expect(findGlPopover().exists()).toBeTruthy();
      });

      it('contains text about Replicated data', () => {
        expect(
          findGlPopover()
            .find(GlSprintf)
            .attributes('message'),
        ).toContain('Replicated data is verified');
      });
    });
  });
});
