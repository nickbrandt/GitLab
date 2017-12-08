# Placeholder class for model that is implemented in EE
# It reserves '&' as a reference prefix, but the table does not exists in CE
class Epic < ActiveRecord::Base
<<<<<<< HEAD
  prepend EE::Epic

  def self.reference_prefix
    '&'
  end

  def self.reference_prefix_escaped
    '&amp;'
||||||| merged common ancestors
  # TODO: this will be implemented as part of #3853
  def to_reference
=======
  def self.reference_prefix
    '&'
  end

  def self.reference_prefix_escaped
    '&amp;'
>>>>>>> ce/10-3-stable
  end
end
