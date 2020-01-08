import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import { STEPS } from '../constants';

const parsePlanData = planData =>
  JSON.parse(planData).map(plan => ({
    value: plan.id,
    text: capitalizeFirstCharacter(plan.code),
    pricePerUserPerYear: plan.price_per_year,
  }));

const determineSelectedPlan = (planId, plans) => {
  if (planId && plans.find(plan => plan.value === planId)) {
    return planId;
  }
  return plans[0] && plans[0].value;
};

export default ({ planData = '[]', planId, setupForCompany, fullName }) => {
  const plans = parsePlanData(planData);

  return {
    currentStep: STEPS[0],
    availablePlans: plans,
    selectedPlan: determineSelectedPlan(planId, plans),
    isSetupForCompany: parseBoolean(setupForCompany),
    fullName,
    organizationName: null,
    numberOfUsers: parseBoolean(setupForCompany) ? 0 : 1,
  };
};
