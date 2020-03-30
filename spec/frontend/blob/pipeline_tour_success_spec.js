import pipelineTourSuccess from '~/blob/pipeline_tour_success_modal.vue';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import { GlSprintf, GlModal } from '@gitlab/ui';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import modalProps from './pipeline_tour_success_mock_data';

describe('PipelineTourSuccessModal', () => {
  let wrapper;
  let cookieSpy;

  beforeEach(() => {
    wrapper = shallowMount(pipelineTourSuccess, {
      propsData: modalProps,
    });

    cookieSpy = jest.spyOn(Cookies, 'remove');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('has expected structure', () => {
    const modal = wrapper.find(GlModal);
    const sprintf = modal.find(GlSprintf);

    expect(modal.attributes('title')).toContain("That's it, well done!");
    expect(sprintf.exists()).toBe(true);
  });

  it('calls to remove cookie', () => {
    wrapper.vm.disableModalFromRenderingAgain();

    expect(cookieSpy).toHaveBeenCalledWith(modalProps.commitCookie);
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('send event for basic view of popover', () => {
      document.body.dataset.page = 'projects:blob:show';

      wrapper.vm.trackOnShow();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, undefined, {
        label: 'congratulate_first_pipeline',
        property: modalProps.humanAccess,
      });
    });
  });
});
