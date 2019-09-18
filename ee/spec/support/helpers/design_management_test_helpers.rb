# frozen_string_literal: true

module DesignManagementTestHelpers
  def enable_design_management(enabled = true)
    stub_licensed_features(design_management: enabled)
    stub_lfs_setting(enabled: enabled)
  end

  def delete_designs(*designs)
    act_on_designs(designs) { ::DesignManagement::Action.deletion }
  end

  def restore_designs(*designs)
    act_on_designs(designs) { ::DesignManagement::Action.creation }
  end

  def modify_designs(*designs)
    act_on_designs(designs) { ::DesignManagement::Action.modification }
  end

  private

  def act_on_designs(designs, &block)
    issue = designs.first.issue
    version = build(:design_version, :empty, issue: issue).tap { |v| v.save(validate: false) }
    designs.each do |d|
      yield.create(design: d, version: version)
    end
    version
  end
end
