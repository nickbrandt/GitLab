import { inactiveId } from '~/boards/constants';

export default () => ({
  endpoints: {},
  isShowingLabels: true,
  activeId: inactiveId,
  configurationOptions: {
    hideOpenList: false,
    hideClosedList: false,
  },
});
