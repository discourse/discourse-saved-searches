# frozen_string_literal: true

module Jobs
  class ScheduleSavedSearches < ::Jobs::Scheduled
    every 5.minutes

    def execute(args)
      SavedSearch.distinct.pluck(:user_id).each do |user_id|
        ::Jobs.enqueue(:saved_search_notification, user_id: user_id)
      end
    end
  end
end
