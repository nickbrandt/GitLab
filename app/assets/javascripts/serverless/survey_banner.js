import Vue from 'vue';
import SurveyBanner from './survey_banner.vue';

export default function initServerlessSurveyBanner() {
  const el = document.querySelector('.js-serverless-survey-banner');
  if (el) {
    const surveyUrl = 'https://gitlab.fra1.qualtrics.com/jfe/form/SV_51J9D8skLbWqdil';
    new Vue({
      el,
      render(createElement) {
        return createElement(SurveyBanner, {
          props: {
            surveyUrl,
          },
        });
      },
    });
  }
}
