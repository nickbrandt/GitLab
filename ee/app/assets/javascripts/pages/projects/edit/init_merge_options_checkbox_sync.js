export default () => {
  const mergePipelinesCheckbox = document.querySelector('.js-merge-options-merge-pipelines');
  const mergeTrainsCheckbox = document.querySelector('.js-merge-options-merge-trains');

  if (mergePipelinesCheckbox && mergeTrainsCheckbox) {
    mergePipelinesCheckbox.addEventListener('change', event => {
      if (!event.target.checked && mergeTrainsCheckbox.checked) {
        mergeTrainsCheckbox.click();
      }
    });

    mergeTrainsCheckbox.addEventListener('change', event => {
      if (event.target.checked && !mergePipelinesCheckbox.checked) {
        mergePipelinesCheckbox.click();
      }
    });
  }
};
