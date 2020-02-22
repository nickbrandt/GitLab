import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import imageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';

describe('ImageDiffViewer', () => {
  const requiredProps = {
    diffMode: 'replaced',
    newPath: GREEN_BOX_IMAGE_URL,
    oldPath: RED_BOX_IMAGE_URL,
  };
  const allProps = {
    ...requiredProps,
    oldSize: 2048,
    newSize: 1024,
  };
  let vm;

  function createComponent(props) {
    const ImageDiffViewer = Vue.extend(imageDiffViewer);
    vm = mountComponent(ImageDiffViewer, props);
  }

  const triggerEvent = (eventName, el = vm.$el, clientX = 0) => {
    const event = document.createEvent('MouseEvents');
    event.initMouseEvent(
      eventName,
      true,
      true,
      window,
      1,
      clientX,
      0,
      clientX,
      0,
      false,
      false,
      false,
      false,
      0,
      null,
    );

    el.dispatchEvent(event);
  };

  const dragSlider = (sliderElement, dragPixel = 20) => {
    triggerEvent('mousedown', sliderElement);
    triggerEvent('mousemove', document.body, dragPixel);
    triggerEvent('mouseup', document.body);
  };

  afterEach(() => {
    vm.$destroy();
  });

  it('renders image diff for replaced', done => {
    createComponent({ ...allProps });

    setTimeout(() => {
      const metaInfoElements = vm.$el.querySelectorAll('.image-info');

      expect(vm.$el.querySelector('.added img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);

      expect(vm.$el.querySelector('.deleted img').getAttribute('src')).toBe(RED_BOX_IMAGE_URL);

      expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe('2-up');
      expect(vm.$el.querySelector('.view-modes-menu li:nth-child(2)').textContent.trim()).toBe(
        'Swipe',
      );

      expect(vm.$el.querySelector('.view-modes-menu li:nth-child(3)').textContent.trim()).toBe(
        'Onion skin',
      );

      expect(metaInfoElements.length).toBe(2);
      expect(metaInfoElements[0]).toHaveText('2.00 KiB');
      expect(metaInfoElements[1]).toHaveText('1.00 KiB');

      done();
    });
  });

  it('renders image diff for new', done => {
    createComponent({ ...allProps, diffMode: 'new', oldPath: '' });

    setTimeout(() => {
      const metaInfoElement = vm.$el.querySelector('.image-info');

      expect(vm.$el.querySelector('.added img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);
      expect(metaInfoElement).toHaveText('1.00 KiB');

      done();
    });
  });

  it('renders image diff for deleted', done => {
    createComponent({ ...allProps, diffMode: 'deleted', newPath: '' });

    setTimeout(() => {
      const metaInfoElement = vm.$el.querySelector('.image-info');

      expect(vm.$el.querySelector('.deleted img').getAttribute('src')).toBe(RED_BOX_IMAGE_URL);
      expect(metaInfoElement).toHaveText('2.00 KiB');

      done();
    });
  });

  it('renders image diff for renamed', done => {
    vm = new Vue({
      components: {
        imageDiffViewer,
      },
      data: {
        ...allProps,
        diffMode: 'renamed',
      },
      template: `
        <image-diff-viewer
          :diff-mode="diffMode"
          :new-path="newPath"
          :old-path="oldPath"
          :new-size="newSize"
          :old-size="oldSize"
        >
          <span slot="image-overlay" class="overlay">test</span>
        </image-diff-viewer>
      `,
    }).$mount();

    setTimeout(() => {
      const metaInfoElement = vm.$el.querySelector('.image-info');

      expect(vm.$el.querySelector('img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);
      expect(vm.$el.querySelector('.overlay')).not.toBe(null);

      expect(metaInfoElement).toHaveText('2.00 KiB');

      done();
    });
  });

  describe('swipeMode', () => {
    beforeEach(done => {
      createComponent({ ...requiredProps });

      setTimeout(() => {
        done();
      });
    });

    it('switches to Swipe Mode', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(2)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe('Swipe');
        done();
      });
    });
  });

  describe('onionSkin', () => {
    beforeEach(done => {
      createComponent({ ...requiredProps });

      setTimeout(() => {
        done();
      });
    });

    it('switches to Onion Skin Mode', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(3)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe(
          'Onion skin',
        );
        done();
      });
    });

    it('has working drag handler', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(3)').click();

      vm.$nextTick(() => {
        dragSlider(vm.$el.querySelector('.dragger'));

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.dragger').style.left).toBe('20px');
          expect(vm.$el.querySelector('.added.frame').style.opacity).toBe('0.2');
          done();
        });
      });
    });
  });
});
