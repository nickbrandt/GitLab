import { s__, sprintf } from '~/locale';
import { glEmojiTag } from '~/emoji';

export const ONBOARDING_DISMISSED_COOKIE_NAME = 'onboarding_dismissed';

export const STORAGE_KEY = 'onboarding_state';

export const AVAILABLE_TOURS = {
  GUIDED_GITLAB_TOUR: 1,
  CREATE_PROJECT_TOUR: 2,
  INVITE_COLLEAGUES_TOUR: 3,
};

export const TOUR_TITLES = [
  { id: AVAILABLE_TOURS.GUIDED_GITLAB_TOUR, title: s__('UserOnboardingTour|Guided GitLab Tour') },
  { id: AVAILABLE_TOURS.CREATE_PROJECT_TOUR, title: s__('UserOnboardingTour|Create a project') },
  {
    id: AVAILABLE_TOURS.INVITE_COLLEAGUES_TOUR,
    title: s__('UserOnboardingTour|Invite colleagues'),
  },
];

export const ONBOARDING_PROPS_DEFAULTS = {
  tourKey: AVAILABLE_TOURS.GUIDED_GITLAB_TOUR,
  lastStepIndex: -1,
  createdProjectPath: '',
};

export const ACCEPTING_MR_LABEL_TEXT = 'Accepting merge requests';

export const LABEL_SEARCH_QUERY = `scope=all&state=opened&label_name[]=${encodeURIComponent(
  ACCEPTING_MR_LABEL_TEXT,
)}`;

export const FEEDBACK_CONTENT = {
  text: sprintf(
    s__(
      "UserOnboardingTour|Great job! %{clapHands} We hope the tour was helpful and that you learned how to use GitLab.%{lineBreak}%{lineBreak}We'd love to get your feedback on this tour.%{lineBreak}%{lineBreak}%{emphasisStart}How helpful would you say this guided tour was?%{emphasisEnd}%{lineBreak}%{lineBreak}",
    ),
    {
      emphasisStart: '<strong>',
      emphasisEnd: '</strong>',
      lineBreak: '<br/>',
      clapHands: glEmojiTag('clap'),
    },
    false,
  ),
  feedbackButtons: true,
  feedbackSize: 5,
};

export const EXIT_TOUR_CONTENT = {
  text: sprintf(
    s__('UserOnboardingTour|Thanks for the feedback! %{thumbsUp}'),
    {
      thumbsUp: glEmojiTag('thumbsup'),
    },
    false,
  ),
  buttonText: s__("UserOnboardingTour|Close 'Learn GitLab'"),
  exitTour: true,
};

export const DNT_EXIT_TOUR_CONTENT = {
  text: sprintf(
    s__(
      'UserOnboardingTour|Thanks for taking the guided tour. Remember, if you want to go through it again, you can start %{emphasisStart}Learn GitLab%{emphasisEnd} in the help menu on the top right.',
    ),
    {
      emphasisStart: '<strong>',
      emphasisEnd: '</strong>',
    },
    false,
  ),
  buttonText: s__('UserOnboardingTour|Got it'),
  exitTour: true,
};
