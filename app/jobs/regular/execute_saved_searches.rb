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
          create_notifications(user, saved_search, posts)
          saved_search.last_post_id = [saved_search.last_post_id, posts.map(&:id).max].max
        end

        saved_search.save!
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
