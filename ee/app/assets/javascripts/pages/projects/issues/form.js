import WeightSelect from 'ee/weight_select';
import initForm from '~/pages/projects/issues/form';

export default () => {
  // eslint-disable-next-line no-new
  new WeightSelect();
  initForm();
};
