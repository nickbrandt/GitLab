import Vue from 'vue';
import ImageViewer from './image_viewer.vue';

export default () => {
  const el = document.getElementById('js-image-viewer');
  const { imagePath, altText } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(ImageViewer, {
        props: {
          imagePath,
          altText,
        },
      });
    },
  });
};
