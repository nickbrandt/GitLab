import { shallowMount } from '@vue/test-utils';
import GeoNodeFormCapacities from 'ee/geo_node_form/components/geo_node_form_capacities.vue';
import { MOCK_NODE } from '../mock_data';

describe('GeoNodeFormCapacities', () => {
  let wrapper;

  const propsData = {
    nodeData: MOCK_NODE,
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoNodeFormCapacities, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormRepositoryCapacityField = () =>
    wrapper.find('#node-repository-capacity-field');
  const findGeoNodeFormFileCapacityField = () => wrapper.find('#node-file-capacity-field');
  const findGeoNodeFormVerificationCapacityField = () =>
    wrapper.find('#node-verification-capacity-field');
  const findGeoNodeFormContainerRepositoryCapacityField = () =>
    wrapper.find('#node-container-repository-capacity-field');
  const findGeoNodeFormReverificationIntervalField = () =>
    wrapper.find('#node-reverification-interval-field');

  describe('template', () => {
    describe.each`
      primaryNode | showRepoCapacity | showFileCapacity | showVerificationCapacity | showContainerCapacity | showReverificationInterval
      ${true}     | ${false}         | ${false}         | ${true}                  | ${true}               | ${true}
      ${false}    | ${true}          | ${true}          | ${true}                  | ${true}               | ${false}
    `(
      `conditional fields`,
      ({
        primaryNode,
        showRepoCapacity,
        showFileCapacity,
        showVerificationCapacity,
        showContainerCapacity,
        showReverificationInterval,
      }) => {
        beforeEach(() => {
          propsData.nodeData.primary = primaryNode;
          createComponent();
        });

        it(`it ${showRepoCapacity ? 'shows' : 'hides'} the Repository Capacity Field`, () => {
          expect(findGeoNodeFormRepositoryCapacityField().exists()).toBe(showRepoCapacity);
        });

        it(`it ${showFileCapacity ? 'shows' : 'hides'} the File Capacity Field`, () => {
          expect(findGeoNodeFormFileCapacityField().exists()).toBe(showFileCapacity);
        });

        it(`it ${
          showVerificationCapacity ? 'shows' : 'hides'
        } the Verification Capacity Field`, () => {
          expect(findGeoNodeFormVerificationCapacityField().exists()).toBe(
            showVerificationCapacity,
          );
        });

        it(`it ${
          showContainerCapacity ? 'shows' : 'hides'
        } the Container Repository Capacity Field`, () => {
          expect(findGeoNodeFormContainerRepositoryCapacityField().exists()).toBe(
            showContainerCapacity,
          );
        });

        it(`it ${
          showReverificationInterval ? 'shows' : 'hides'
        } the Reverification Interval Field`, () => {
          expect(findGeoNodeFormReverificationIntervalField().exists()).toBe(
            showReverificationInterval,
          );
        });
      },
    );
  });

  describe('computed', () => {
    describe('visibleFormGroups', () => {
      describe('when nodeData.primary is true', () => {
        beforeEach(() => {
          propsData.nodeData.primary = true;
          createComponent();
        });

        it('contains conditional form groups for primary', () => {
          expect(wrapper.vm.visibleFormGroups.some(g => g.conditional === 'primary')).toBeTruthy();
        });

        it('does not contain conditional form groups for secondary', () => {
          expect(wrapper.vm.visibleFormGroups.some(g => g.conditional === 'secondary')).toBeFalsy();
        });
      });

      describe('when nodeData.primary is false', () => {
        beforeEach(() => {
          propsData.nodeData.primary = false;
          createComponent();
        });

        it('contains conditional form groups for secondary', () => {
          expect(
            wrapper.vm.visibleFormGroups.some(g => g.conditional === 'secondary'),
          ).toBeTruthy();
        });

        it('does not contain conditional form groups for primary', () => {
          expect(wrapper.vm.visibleFormGroups.some(g => g.conditional === 'primary')).toBeFalsy();
        });
      });
    });
  });
});
