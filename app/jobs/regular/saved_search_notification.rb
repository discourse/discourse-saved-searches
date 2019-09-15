# frozen_string_literal: true

require_dependency 'system_message'

module Jobs
  class SavedSearchNotification < ::Jobs::Base

    sidekiq_options queue: 'low'

    def execute(args)
      if user = User.where(id: args[:user_id]).first
        return if !user.staff? && user.trust_level < SiteSetting.saved_searches_min_trust_level

        since = Jobs::ScheduleSavedSearches::SEARCH_INTERVAL.ago
        min_post_id = user.custom_fields['saved_searches_min_post_id'].to_i
        new_min_post_id = min_post_id

        if searches = (user.custom_fields['saved_searches'] || {})['searches']
          searches.each do |term|
            search = Search.new(
              "#{term} in:unseen after:#{since.strftime("%Y-%-m-%-d")} order:latest",
              guardian: Guardian.new(user),
              type_filter: 'topic'
            )

            results = search.execute

            if results.posts.count > 0 && results.posts.first.id > min_post_id
              posts = results.posts.reject { |post| post.user_id == user.id || post.post_type != Post.types[:regular] }
              if posts.size > 0
                results_notification(user, term, posts)
                new_min_post_id = [new_min_post_id, posts.map(&:id).max].max
              end
            end
          end
        end

        if new_min_post_id > user.custom_fields['saved_searches_min_post_id'].to_i
          user.custom_fields['saved_searches_min_post_id'] = new_min_post_id
          user.save
        end
      end
    end

    def results_notification(user, term, posts)
      if posts.size > 0
        posts_raw = if posts.size < 6
          posts.map(&:full_url).join("\n\n".freeze)
        else
          posts.map do |post|
            I18n.t('system_messages.saved_searches_notification.post_link_text',
              title: post.topic&.title,
              post_number: post.post_number,
              url: post.url
            )
          end.join("\n".freeze)
        end

        # Find existing topic for this search term
        if tcf = TopicCustomField.joins(:topic).where(name: custom_field_name(user), value: term).last
          topic = tcf.topic
          PostCreator.create!(Discourse.system_user,
            topic_id: topic.id,
            raw: I18n.t('system_messages.saved_searches_notification.text_body_template', posts: posts_raw, term: term),
            skip_validations: true)
        else
          post = SystemMessage.create_from_system_user(user, :saved_searches_notification, posts: posts_raw, term: term)
          topic = post.topic
          topic.custom_fields[custom_field_name(user)] = term
          topic.save
          post
        end
      end
    end

    def custom_field_name(user)
      "pm_saved_search_results_#{user.id}"
    end

  end
end
