module Jobs
  class ScheduleSavedSearches < Jobs::Scheduled

    SEARCH_INTERVAL = 1.day

    every SEARCH_INTERVAL

    def execute(args)
      user_ids.each do |user_id|
        Jobs.enqueue(:saved_search_notification, user_id: user_id)
      end
    end

    def user_ids
      UserCustomField.where(name: 'saved_searches').pluck(:user_id)
    end

  end
end
