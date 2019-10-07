# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::LicenseScanning::Report do
  subject { build(:ci_reports_license_management_report, :mit) }

  describe '#violates?' do
    let(:project) { create(:project) }
    let(:mit_license) { build(:software_license, :mit) }
    let(:apache_license) { build(:software_license, :apache_2_0) }

    context "when a blacklisted license is found in the report" do
      let(:mit_blacklist) { build(:software_license_policy, :blacklist, software_license: mit_license) }

      before do
        project.software_license_policies << mit_blacklist
      end

      specify { expect(subject.violates?(project.software_license_policies)).to be(true) }
    end

    context "when a blacklisted license is discovered with a different casing for the name" do
      let(:mit_blacklist) { build(:software_license_policy, :blacklist, software_license: mit_license) }

      before do
        mit_license.update!(name: 'mit')
        project.software_license_policies << mit_blacklist
      end

      specify { expect(subject.violates?(project.software_license_policies)).to be(true) }
    end

    context "when none of the licenses discovered in the report violate the blacklist policy" do
      let(:apache_blacklist) { build(:software_license_policy, :blacklist, software_license: apache_license) }

      before do
        project.software_license_policies << apache_blacklist
      end

      specify { expect(subject.violates?(project.software_license_policies)).to be(false) }
    end
  end

  describe "#diff_with" do
    let(:report_1) { build(:ci_reports_license_management_report, :report_1) }
    let(:report_2) { build(:ci_reports_license_management_report, :report_2) }
    subject { report_1.diff_with(report_2) }

    before do
      report_1.add_dependency('BSD', 1, 'https://opensource.org/licenses/0BSD', 'Library1')
      report_2.add_dependency('bsd', 1, 'https://opensource.org/licenses/0BSD', 'Library1')
    end

    def names_from(licenses)
      licenses.map(&:name)
    end

    it { expect(names_from(subject[:added])).to contain_exactly('Apache 2.0') }
    it { expect(names_from(subject[:unchanged])).to contain_exactly('MIT', 'BSD') }
    it { expect(names_from(subject[:removed])).to contain_exactly('WTFPL') }
  end

  describe "#empty?" do
    let(:completed_report) { build(:ci_reports_license_management_report, :report_1) }
    let(:empty_report) { build(:ci_reports_license_management_report) }

    it { expect(empty_report).to be_empty }
    it { expect(completed_report).not_to be_empty }
  end
end
