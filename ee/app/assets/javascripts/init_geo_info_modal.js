import $ from 'jquery';

export default () => {
  const $modal = $('#modal-geo-info');

  if (!$modal.length) return;

  $modal.appendTo('body').modal({
    modal: true,
    show: false,
  });
};
