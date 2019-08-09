import Tracking from '~/tracking';

export default () => {
  document.querySelector('.main-notes-list').addEventListener('click', event => {
    const isReplyButtonClick = event.target.parentElement.classList.contains(
      'js-note-action-reply',
    );

    if (isReplyButtonClick) {
      Tracking.event(document.body.dataset.page, 'click_button', {
        label: 'reply_comment_button',
        property: '',
        value: '',
      });
    }
  });

  new Tracking().bind();
};
