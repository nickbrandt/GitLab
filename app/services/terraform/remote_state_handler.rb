# frozen_string_literal: true

module Terraform
  class RemoteStateHandler < BaseService
    StateLockedError = Class.new(StandardError)

    def create_or_find!
      raise ArgumentError unless params[:name].present?

      Terraform::State.create_or_find_by(project: project, name: params[:name])
    end

    def handle_with_lock
      retrieve_with_lock do |state|
        raise StateLockedError unless lock_matches?(state)

        yield state if block_given?

        state.save!
        state.update_file_store!
      end
    end

    def lock!
      raise ArgumentError if params[:lock_id].blank?

      retrieve_with_lock do |state|
        raise StateLockedError if state.locked?

        state.lock_xid = params[:lock_id]
        state.locked_by = current_user
        state.locked_at = Time.now

        state.save!
      end
    end

    def unlock!
      raise ArgumentError if params[:lock_id].blank?

      retrieve_with_lock do |state|
        raise StateLockedError unless lock_matches?(state)

        state.lock_xid = nil
        state.locked_by = nil
        state.locked_at = nil

        state.save!
      end
    end

    private

    def retrieve_with_lock
      create_or_find!.tap { |state| state.with_lock { yield state } }
    end

    def lock_matches?(state)
      return true if state.lock_xid.nil? && params[:lock_id].nil?

      ActiveSupport::SecurityUtils
        .secure_compare(state.lock_xid.to_s, params[:lock_id].to_s)
    end
  end
end
