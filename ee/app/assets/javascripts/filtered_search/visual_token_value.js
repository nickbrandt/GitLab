import VisualTokenValueCE from '~/filtered_search/visual_token_value';

export default class VisualTokenValue {
  constructor(tokenValue, tokenType) {
    this.tokenValue = tokenValue;
    this.tokenType = tokenType;

    this.visualTokenValueCE = new VisualTokenValueCE(tokenValue, tokenType);
  }

  render(tokenValueContainer, tokenValueElement) {
    if (this.tokenType === 'approver') {
      this.visualTokenValueCE.updateUserTokenAppearance(tokenValueContainer, tokenValueElement);
    } else {
      this.visualTokenValueCE.render(tokenValueContainer, tokenValueElement);
    }
  }
}
