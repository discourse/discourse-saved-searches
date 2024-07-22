# frozen_string_literal: true

module Jobs
  class ScheduleSavedSearches < ::Jobs::Scheduled
    every 5.minutes

    def execute(args)
      return if !SiteSetting.saved_searches_enabled

      SavedSearch
        .distinct
        .pluck(:user_id)
        .each { |user_id| ::Jobs.enqueue(:execute_saved_searches, user_id: user_id) }
    end
  end
end
