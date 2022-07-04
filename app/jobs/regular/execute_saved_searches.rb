# frozen_string_literal: true

module Jobs
  class ExecuteSavedSearches < ::Jobs::Base
    sidekiq_options queue: 'low'

    def execute(args)
      user = User.find_by(id: args[:user_id])
      return if !user || !user.active? || user.suspended? || !user.guardian.can_use_saved_searches?

      user.saved_searches.each do |saved_search|
        time_1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        time_2 = nil

        # Skip saved search if it is not due yet
        if saved_search.frequency != SavedSearch.frequencies[:immediately]
          case saved_search.frequency
          when SavedSearch.frequencies[:daily]
            next if saved_search.last_searched_at > 1.day.ago
          when SavedSearch.frequencies[:weekly]
            next if saved_search.last_searched_at > 1.week.ago
          when SavedSearch.frequencies[:monthly]
            next if saved_search.last_searched_at > 1.month.ago
          end
        end

        # Store creation date of the last indexed post to use it as a starting
        # point for future searches
        saved_search.last_searched_at = DB.query_single(<<~SQL).first || Time.zone.now
          SELECT created_at
          FROM posts
          WHERE id = (SELECT MAX(post_id) FROM post_search_data)
        SQL

        # Skip current saved search if no new posts match. This should be
        # faster than a full search.
        if saved_search.compiled_query
          params = {
            last_post_id: saved_search.last_post_id,
            last_searched_at: saved_search.last_searched_at_was,
            compiled_query: saved_search.compiled_query
          }

          result = DB.query_single(<<~SQL, params).first
            SELECT 1
            FROM posts
            JOIN post_search_data ON posts.id = post_search_data.post_id
            WHERE posts.id > :last_post_id AND
                  posts.created_at > :last_searched_at AND
                  post_search_data.search_data @@ :compiled_query::tsquery
            LIMIT 1
          SQL

          time_2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          if !result
            Rails.logger.warn("SQL-only search for user #{user.id} and saved search #{saved_search.id} took #{time_2 - time_1}s. No results were found") if SiteSetting.debug_saved_searches?
            next saved_search.save!
          end
        end

        # Perform a full search with all advanced filter and permission
        search = Search.new(
          "#{saved_search.query} min-post-id:#{saved_search.last_post_id} min-created-at:\"#{saved_search.last_searched_at_was}\" in:unseen order:latest",
          guardian: user.guardian,
          type_filter: 'topic',
          saved_search: true
        )
        results = search.execute

        time_3 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        Rails.logger.warn("SQL-only search for user #{user.id} and saved search #{saved_search.id} took #{time_2 - time_1}s, full search took #{time_3 - time_2}. Found #{results.posts.size} posts") if SiteSetting.debug_saved_searches?

        posts = results.posts.reject { |post| post.user_id == user.id || post.post_type != Post.types[:regular] }
        if posts.size > 0
          if saved_search.frequency != SavedSearch.frequencies[:immediately]
            create_digest(user, saved_search, posts)
          else
            create_notifications(user, saved_search, posts)
          end
          saved_search.last_post_id = [saved_search.last_post_id, posts.map(&:id).max].max
        end

        saved_search.save!
      end
    end

    private

    def create_digest(user, saved_search, posts)
      posts_raw = if posts.size < 6
        posts.map(&:full_url).join("\n\n")
      else
        posts.map do |post|
          I18n.t('system_messages.saved_searches_notification.post_link_text',
            title: post.topic&.title,
            post_number: post.post_number,
            url: post.url
          )
        end.join("\n")
      end

      custom_field_name = "pm_saved_search_results_#{user.id}"

      # Find existing topic for this search term
      if tcf = TopicCustomField.joins(:topic).where(name: custom_field_name, value: saved_search.query).last
        PostCreator.create!(
          Discourse.system_user,
          topic_id: tcf.topic_id,
          raw: I18n.t('system_messages.saved_searches_notification.text_body_template', term: saved_search.query, posts: posts_raw),
          skip_validations: true
        )
      else
        post = SystemMessage.create_from_system_user(user, :saved_searches_notification, term: saved_search.query, posts: posts_raw)
        post.topic.upsert_custom_fields(custom_field_name => saved_search.query)
      end
    end

    def create_notifications(user, saved_search, posts)
      posts.each do |post|
        user.notifications.create!(
          notification_type: Notification.types[:custom],
          topic_id: post.topic_id,
          post_number: post.post_number,
          data: {
            saved_search_id: saved_search.id,
            message: "saved_searches.notification",
            display_username: post.user.username,
            topic_title: post.topic.title,
          }.to_json
        )
      end
    end
  end
end
