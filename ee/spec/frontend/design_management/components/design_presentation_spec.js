import { shallowMount } from '@vue/test-utils';
import DesignPresentation from 'ee/design_management/components/design_presentation.vue';

const mockOverlayData = {
  overlayDimensions: {
    width: 100,
    height: 100,
  },
  overlayPosition: {
    top: '0',
    left: '0',
  },
};

describe('Design management design presentation component', () => {
  let wrapper;

  function createComponent(
    { image, imageName, discussions = [], isAnnotating = false } = {},
    data = {},
  ) {
    wrapper = shallowMount(DesignPresentation, {
      propsData: {
        image,
        imageName,
        discussions,
        isAnnotating,
      },
    });

    wrapper.setData(data);
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders image and overlay when image provided', () => {
    createComponent(
      {
        image: 'test.jpg',
        imageName: 'test',
      },
      mockOverlayData,
    );

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders empty state when no image provided', () => {
    createComponent();

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('openCommentForm event emits correct data', () => {
    createComponent(
      {
        image: 'test.jpg',
        imageName: 'test',
      },
      mockOverlayData,
    );

    wrapper.vm.openCommentForm({ x: 1, y: 1 });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('openCommentForm')).toEqual([
        [{ ...mockOverlayData.overlayDimensions, x: 1, y: 1 }],
      ]);
    });
  });

  it('currentCommentForm is null when isAnnotating is false', () => {
    createComponent({
      image: 'test.jpg',
      imageName: 'test',
    });

    expect(wrapper.vm.currentCommentForm).toBeNull();
  });

  it('currentCommentForm is null when isAnnotating is true but annotation coordinates are falsey', () => {
    createComponent({
      image: 'test.jpg',
      imageName: 'test',
      isAnnotating: true,
    });

    expect(wrapper.vm.currentCommentForm).toBeNull();
  });

  it('currentCommentForm is equal to current annotation coordinates when isAnnotating is true', () => {
    createComponent(
      {
        image: 'test.jpg',
        imageName: 'test',
        isAnnotating: true,
      },
      {
        currentAnnotationCoordinates: {
          x: 1,
          y: 1,
          width: 100,
          height: 100,
        },
      },
    );

    expect(wrapper.vm.currentCommentForm).toEqual({
      x: 1,
      y: 1,
      width: 100,
      height: 100,
    });
  });

  describe('setOverlayPosition', () => {
    beforeEach(() => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayData,
      );
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('sets overlay position correctly when overlay is smaller than viewport', () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(200);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(200);

      wrapper.vm.setOverlayPosition();
      expect(wrapper.vm.overlayPosition).toEqual({
        left: `calc(50% - ${mockOverlayData.overlayDimensions.width / 2}px)`,
        top: `calc(50% - ${mockOverlayData.overlayDimensions.height / 2}px)`,
      });
    });

    it('sets overlay position correctly when overlay width is larger than viewports', () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(50);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(200);

      wrapper.vm.setOverlayPosition();
      expect(wrapper.vm.overlayPosition).toEqual({
        left: '0',
        top: `calc(50% - ${mockOverlayData.overlayDimensions.height / 2}px)`,
      });
    });

    it('sets overlay position correctly when overlay height is larger than viewports', () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(200);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(50);

      wrapper.vm.setOverlayPosition();
      expect(wrapper.vm.overlayPosition).toEqual({
        left: `calc(50% - ${mockOverlayData.overlayDimensions.width / 2}px)`,
        top: '0',
      });
    });
  });
});
