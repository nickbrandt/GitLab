# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::LicenseScanning::Report do
  subject { build(:ci_reports_license_scanning_report, :mit) }

  describe '#violates?' do
    let(:project) { create(:project) }
    let(:mit_license) { build(:software_license, :mit) }
    let(:apache_license) { build(:software_license, :apache_2_0) }

    context 'when a blacklisted license is found in the report' do
      let(:mit_blacklist) { build(:software_license_policy, :blacklist, software_license: mit_license) }

      before do
        project.software_license_policies << mit_blacklist
      end

      it { expect(subject.violates?(project.software_license_policies)).to be(true) }
    end

    context 'when a blacklisted license is discovered with a different casing for the name' do
      let(:mit_blacklist) { build(:software_license_policy, :blacklist, software_license: mit_license) }

      before do
        mit_license.update!(name: 'mit')
        project.software_license_policies << mit_blacklist
      end

      it { expect(subject.violates?(project.software_license_policies)).to be(true) }
    end

    context 'when none of the licenses discovered in the report violate the blacklist policy' do
      let(:apache_blacklist) { build(:software_license_policy, :blacklist, software_license: apache_license) }

      before do
        project.software_license_policies << apache_blacklist
      end

      it { expect(subject.violates?(project.software_license_policies)).to be(false) }
    end
  end

  describe '#diff_with' do
    def names_from(licenses)
      licenses.map(&:name)
    end

    context 'when diffing two v1 reports' do
      let(:base_report) { build(:license_scan_report, :version_1) }
      let(:head_report) { build(:license_scan_report, :version_1) }
      subject { base_report.diff_with(head_report) }

      before do
        base_report.add_license(id: nil, name: 'MIT').add_dependency('Library1')
        base_report.add_license(id: nil, name: 'BSD').add_dependency('Library1')
        base_report.add_license(id: nil, name: 'WTFPL').add_dependency('Library2')

        head_report.add_license(id: nil, name: 'MIT').add_dependency('Library1')
        head_report.add_license(id: nil, name: 'Apache 2.0').add_dependency('Library3')
        head_report.add_license(id: nil, name: 'bsd').add_dependency('Library1')
      end

      it { expect(names_from(subject[:added])).to contain_exactly('Apache 2.0') }
      it { expect(names_from(subject[:unchanged])).to contain_exactly('MIT', 'BSD') }
      it { expect(names_from(subject[:removed])).to contain_exactly('WTFPL') }
    end

    context 'when diffing two v2 reports' do
      let(:base_report) { build(:license_scan_report, :version_2) }
      let(:head_report) { build(:license_scan_report, :version_2) }
      subject { base_report.diff_with(head_report) }

      before do
        base_report.add_license(id: 'MIT', name: 'MIT').add_dependency('Library1')
        base_report.add_license(id: 'BSD-3-Clause', name: 'BSD').add_dependency('Library1')
        base_report.add_license(id: 'WTFPL', name: 'WTFPL').add_dependency('Library2')

        head_report.add_license(id: 'BSD-3-Clause', name: 'bsd').add_dependency('Library1')
        head_report.add_license(id: 'Apache-2.0', name: 'Apache 2.0').add_dependency('Library3')
        head_report.add_license(id: 'MIT', name: 'MIT License').add_dependency('Library1')
      end

      it { expect(names_from(subject[:added])).to contain_exactly('Apache 2.0') }
      it { expect(names_from(subject[:unchanged])).to contain_exactly('MIT', 'BSD') }
      it { expect(names_from(subject[:removed])).to contain_exactly('WTFPL') }
    end

    context 'when diffing a v1 report with a v2 report' do
      let(:base_report) { build(:license_scan_report, :version_1) }
      let(:head_report) { build(:license_scan_report, :version_2) }
      subject { base_report.diff_with(head_report) }

      before do
        base_report.add_license(id: nil, name: 'MIT').add_dependency('Library1')
        base_report.add_license(id: nil, name: 'BSD').add_dependency('Library1')
        base_report.add_license(id: nil, name: 'WTFPL').add_dependency('Library2')

        head_report.add_license(id: 'BSD-3-Clause', name: 'bsd').add_dependency('Library1')
        head_report.add_license(id: 'Apache-2.0', name: 'Apache 2.0').add_dependency('Library3')
        head_report.add_license(id: 'MIT', name: 'MIT').add_dependency('Library1')
      end

      it { expect(names_from(subject[:added])).to contain_exactly('Apache 2.0') }
      it { expect(names_from(subject[:unchanged])).to contain_exactly('MIT', 'BSD') }
      it { expect(names_from(subject[:removed])).to contain_exactly('WTFPL') }
    end

    context 'when diffing a v2 report with a v1 report' do
      let(:base_report) { build(:license_scan_report, :version_2) }
      let(:head_report) { build(:license_scan_report, :version_1) }
      subject { base_report.diff_with(head_report) }

      before do
        base_report.add_license(id: 'MIT', name: 'MIT').add_dependency('Library1')
        base_report.add_license(id: 'BSD-3-Clause', name: 'BSD').add_dependency('Library1')
        base_report.add_license(id: 'WTFPL', name: 'WTFPL').add_dependency('Library2')

        head_report.add_license(id: nil, name: 'bsd').add_dependency('Library1')
        head_report.add_license(id: nil, name: 'Apache 2.0').add_dependency('Library3')
        head_report.add_license(id: nil, name: 'MIT').add_dependency('Library1')
      end

      it { expect(names_from(subject[:added])).to contain_exactly('Apache 2.0') }
      it { expect(names_from(subject[:unchanged])).to contain_exactly('MIT', 'BSD') }
      it { expect(names_from(subject[:removed])).to contain_exactly('WTFPL') }
    end
  end

  describe '#empty?' do
    let(:completed_report) { build(:ci_reports_license_scanning_report, :report_1) }
    let(:empty_report) { build(:ci_reports_license_scanning_report) }

    it { expect(empty_report).to be_empty }
    it { expect(completed_report).not_to be_empty }
  end

  describe '.parse_from' do
    context 'when parsing a v1 report' do
      subject { described_class.parse_from(v1_json) }
      let(:v1_json) { fixture_file('security_reports/master/gl-license-management-report.json', dir: 'ee') }

      it { expect(subject.version).to eql('1.0') }
      it { expect(subject.licenses.count).to eq(4) }
    end

    context 'when parsing a v2 report' do
      subject { described_class.parse_from(v2_json) }
      let(:v2_json) { fixture_file('security_reports/gl-license-management-report-v2.json', dir: 'ee') }

      it { expect(subject.version).to eql('2.0') }
      it { expect(subject.licenses.count).to eq(3) }
    end
  end
end
