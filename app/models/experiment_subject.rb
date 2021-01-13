# frozen_string_literal: true

class ExperimentSubject < ApplicationRecord
  include ::Gitlab::Experimentation::GroupTypes

  belongs_to :experiment, inverse_of: :experiment_subjects
  belongs_to :user
  belongs_to :group
  belongs_to :project

  validates :experiment, presence: true
  validates :variant, presence: true
  validate :must_have_one_subject_present

  enum variant: { GROUP_CONTROL => 0, GROUP_EXPERIMENTAL => 1 }

  SUBJECT_ATTRS = %i[user group project].freeze

  class << self
    def find_by_subject(subject)
      find_by(parameterized_subject(subject))
    end

    def find_or_initialize_by_subject(subject)
      find_or_initialize_by(parameterized_subject(subject))
    end

    private

    def parameterized_subject(subject)
      param_key = subject.class.model_name.param_key.to_sym

      raise unless SUBJECT_ATTRS.include?(param_key)

      { param_key => subject }
    rescue
      raise ArgumentError.new(s_("ExperimentSubject|subject must be of type User, Group, or Project but was %{obj_class}.") % { obj_class: subject.class.inspect })
    end
  end

  def subject
    non_nil_subjects.first
  end

  def subject=(subject)
    if subject.nil?
      clear_subject
      return
    end

    subject_model = subject.class.model_name

    subject_attrs = SUBJECT_ATTRS.dup
    subject_attr = subject_attrs.delete(subject_model.param_key.to_sym)

    if subject_attr.nil?
      raise ActiveRecord::AssociationTypeMismatch.new(s_("ExperimentSubject|Expected subject to be of type User, Group, or Project but was %{type}" % { type: subject_model.name }))
    end

    # rubocop:disable GitlabSecurity/PublicSend
    self.send(:"#{subject_attr}=", subject)
    subject_attrs.each {|attr| self.send(:"#{attr}=", nil) }
    # rubocop:enable GitlabSecurity/PublicSend
  end

  private

  def clear_subject
    SUBJECT_ATTRS.each do |attr|
      self.send(:"#{attr}=", nil) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def non_nil_subjects
    # rubocop:disable GitlabSecurity/PublicSend
    SUBJECT_ATTRS.map {|attr| self.send(attr) }.reject(&:blank?)
    # rubocop:enable GitlabSecurity/PublicSend
  end

  def must_have_one_subject_present
    if non_nil_subjects.size != 1
      errors.add(:base, s_("ExperimentSubject|Must have exactly one of User, Group, or Project."))
    end
  end
end
