module Jobs
  class SavedSearchNotification < Jobs::Base

    sidekiq_options queue: 'low'

    def execute(args)
      if user = User.where(id: args[:user_id]).first
        # perform search
        # send notification with links to new results
      end
    end

  end
end
