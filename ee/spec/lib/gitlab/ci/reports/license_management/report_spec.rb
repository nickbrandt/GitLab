# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::LicenseManagement::Report do
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
end
