import { GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Status from 'ee/sidebar/components/status/status.vue';
import { healthStatus, healthStatusColorMap, healthStatusTextMap } from 'ee/sidebar/constants';

const getStatusText = wrapper => wrapper.find('.value').text();

const getTooltipText = wrapper => wrapper.find(GlTooltip).text();

const getStatusIconCssClasses = wrapper => wrapper.find('[name="severity-low"]').classes();

describe('Status', () => {
  let wrapper;

  function shallowMountStatus(propsData) {
    wrapper = shallowMount(Status, {
      propsData,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows the text "Status"', () => {
    shallowMountStatus();

    expect(wrapper.find('.title').text()).toBe('Status');
  });

  describe('loading icon', () => {
    it('shows loader while retrieving data', () => {
      const props = {
        isFetching: true,
      };

      shallowMountStatus(props);

      expect(wrapper.contains(GlLoadingIcon)).toBe(true);
    });

    it('does not show loader when not retrieving data', () => {
      const props = {
        isFetching: false,
      };

      shallowMountStatus(props);

      expect(wrapper.contains(GlLoadingIcon)).toBe(false);
    });
  });

  describe('status text', () => {
    describe('when no value is provided for status', () => {
      beforeEach(() => {
        const props = {
          status: '',
        };

        shallowMountStatus(props);
      });

      it('shows "None"', () => {
        expect(getStatusText(wrapper)).toBe('None');
      });

      it('shows "Status" in the tooltip', () => {
        expect(getTooltipText(wrapper)).toBe('Status');
      });
    });

    describe.each(Object.values(healthStatus))(`when "%s" is provided for status`, statusValue => {
      beforeEach(() => {
        const props = {
          status: statusValue,
        };

        shallowMountStatus(props);
      });

      it(`shows "${healthStatusTextMap[statusValue]}"`, () => {
        expect(getStatusText(wrapper)).toBe(healthStatusTextMap[statusValue]);
      });

      it(`shows "Status: ${healthStatusTextMap[statusValue]}" in the tooltip`, () => {
        expect(getTooltipText(wrapper)).toBe(`Status: ${healthStatusTextMap[statusValue]}`);
      });

      it(`uses ${healthStatusColorMap[statusValue]} color for the status icon`, () => {
        expect(getStatusIconCssClasses(wrapper)).toContain(healthStatusColorMap[statusValue]);
      });
    });
  });
});
