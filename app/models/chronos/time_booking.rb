module Chronos
  class TimeBooking < ActiveRecord::Base
    include Namespace
    include IsoStartStop

    belongs_to :time_log
    belongs_to :time_entry, dependent: :delete

    after_initialize :create_time_entry
    after_update :update_time_entry
    after_validation :add_time_entry_errors

    attr_accessor :time_entry_arguments

    validates_presence_of :time_log, :time_entry, :start, :stop
    validate :stop_is_valid
    validates_associated :time_entry

    delegate :issue, :issue_id,
             :project, :project_id,
             :activity, :activity_id,
             :user, :user_id,
             :comments,
             to: :time_entry,
             allow_nil: true

    def rounding_carry_over
      (stop - time_log.stop).to_i
    end

    private
    def create_time_entry
      if time_entry_arguments.present? && !time_entry
        super time_entry_arguments
      end
    end

    def update_time_entry
      if time_entry_arguments.present? && time_entry
        time_entry.update time_entry_arguments
      end
    end

    def add_time_entry_errors
      filtered_errors = self.errors.reject { |err| err.first == :time_entry }
      self.errors.clear
      filtered_errors.each { |err| self.errors.add(*err) }
      time_entry.errors.full_messages.each { |msg| errors.add :base, msg } if time_entry.present?
    end

    def stop_is_valid
      #this is different from the stop validation of time log
      errors.add :stop, :invalid if stop.present? && start.present? && stop < start
    end
  end
end
