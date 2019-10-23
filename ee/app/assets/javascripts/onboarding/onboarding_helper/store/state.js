import { AVAILABLE_TOURS } from '../../constants';

export default () => ({
  url: '',
  projectFullPath: '',
  projectName: '',
  tourData: [],
  tourKey: AVAILABLE_TOURS.GUIDED_GITLAB_TOUR,
  helpContentIndex: 0,
  lastStepIndex: -1,
  dismissed: false,
  createdProjectPath: '',
  exitTour: false,
  tourFeedback: false,
  dntExitTour: false,
});
