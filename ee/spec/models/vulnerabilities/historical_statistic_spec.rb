# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::HistoricalStatistic do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:letter_grade) }
    it { is_expected.to validate_numericality_of(:total).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:critical).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:high).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:medium).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:low).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:unknown).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:info).is_greater_than_or_equal_to(0) }
    it { is_expected.to define_enum_for(:letter_grade).with_values(%i(a b c d f)) }
  end

  describe '.older_than' do
    let_it_be(:statistic_1) { create(:vulnerability_historical_statistic, date: 99.days.ago) }
    let_it_be(:statistic_2) { create(:vulnerability_historical_statistic, date: 100.days.ago) }
    let_it_be(:statistic_3) { create(:vulnerability_historical_statistic, date: 101.days.ago) }

    subject(:older_than) { described_class.older_than(days: 100) }

    it { is_expected.to match_array([statistic_2, statistic_3]) }
  end
end
