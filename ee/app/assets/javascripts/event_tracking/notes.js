import Stats from 'ee/stats';

export default () => {
  document.querySelector('.main-notes-list').addEventListener('click', event => {
    const isReplyButtonClick = event.path.find(
      el => el.classList && el.classList.contains('js-reply-button'),
    );

    if (isReplyButtonClick) {
      Stats.trackEvent(document.body.dataset.page, 'click_button', {
        label: 'reply_comment_button',
        property: '',
        value: '',
      });
    }
  });

  Stats.bindTrackableContainer('.js-main-target-form');
};
