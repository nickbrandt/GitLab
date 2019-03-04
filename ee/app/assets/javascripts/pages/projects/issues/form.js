import initForm from '~/pages/projects/issues/form';
import WeightSelect from 'ee/weight_select';

export default () => {
  // eslint-disable-next-line no-new
  new WeightSelect();
  initForm();
};
