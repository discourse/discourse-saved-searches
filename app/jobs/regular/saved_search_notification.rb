require_dependency 'system_message'

module Jobs
  class SavedSearchNotification < Jobs::Base

    sidekiq_options queue: 'low'

    def execute(args)
      if user = User.where(id: args[:user_id]).first
        return if !user.staff? && user.trust_level < SiteSetting.saved_searches_min_trust_level

        since = Jobs::ScheduleSavedSearches::SEARCH_INTERVAL.ago
        min_post_id = user.custom_fields['saved_searches_min_post_id'].to_i
        posts = []

        if searches = (user.custom_fields['saved_searches'] || {})['searches']
          searches.each do |term|
            search = Search.new("#{term} in:unseen after:#{since.strftime("%Y-%-m-%-d")} order:latest", guardian: Guardian.new(user))
            results = search.execute
            if results.posts.count > 0 && results.posts.first.id > min_post_id
              posts += results.posts
            end
          end
        end

        posts.uniq!
        posts.reject! { |post| post.user_id == user.id }

        if posts.size > 0
          SystemMessage.create_from_system_user(
            user,
            :saved_searches_notification,
            posts: posts.map do |post|
              I18n.t('system_messages.saved_searches_notification.post_link_text',
                title: post.topic&.title,
                post_number: post.post_number,
                url: post.url
              )
            end.join("\n".freeze)
          )
          min_post_id = [min_post_id, posts.map(&:id).max].max
        end

        if min_post_id > user.custom_fields['saved_searches_min_post_id'].to_i
          user.custom_fields['saved_searches_min_post_id'] = min_post_id
          user.save
        end
      end
    end

  end
end
