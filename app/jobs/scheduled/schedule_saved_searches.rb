# frozen_string_literal: true

module Jobs
  class ScheduleSavedSearches < ::Jobs::Scheduled
    every SavedSearches::SEARCH_INTERVAL

    def execute(args)
      user_ids.each do |user_id|
        ::Jobs.enqueue(:saved_search_notification, user_id: user_id)
      end
    end

    def user_ids
      SavedSearch.distinct.pluck(:user_id)
    end
  end
end
