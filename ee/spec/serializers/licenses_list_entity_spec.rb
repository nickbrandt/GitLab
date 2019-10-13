# frozen_string_literal: true

require 'spec_helper'

describe LicensesListEntity do
  let(:report) { build(:ci_reports_license_management_report, :mit) }

  it_behaves_like 'report list' do
    let(:name) { :licenses }
    let(:collection) { report.licenses }
    let(:no_items_status) { :no_licenses }
  end
end
