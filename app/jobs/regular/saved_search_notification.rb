# frozen_string_literal: true

module Jobs
  class SavedSearchNotification < ::Jobs::Base
    sidekiq_options queue: 'low'

    def execute(args)
      user = User.find_by(id: args[:user_id])
      return if !user || !user.active? || user.suspended? || !user.guardian.can_use_saved_searches?

      user.saved_searches.each do |saved_search|
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

          next saved_search.save! if !result
        end

        # Perform a full search with all advanced filter and permission
        search = Search.new(
          "#{saved_search.query} min-post-id:#{saved_search.last_post_id} min-created-at:\"#{saved_search.last_searched_at_was}\" in:unseen order:latest",
          guardian: user.guardian,
          type_filter: 'topic',
          saved_search: true
        )
        results = search.execute

        posts = results.posts.reject { post.user_id == user.id || post.post_type != Post.types[:regular] }
        if posts.size > 0
          results_notification(user, saved_search.query, posts)
          saved_search.last_post_id = [saved_search.last_post_id, posts.map(&:id).max].max
        end

        saved_search.save!
      end
    end

    def results_notification(user, term, posts)
      return if posts.blank?

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
        PostCreator.create!(
          Discourse.system_user,
          topic_id: tcf.topic_id,
          raw: I18n.t('system_messages.saved_searches_notification.text_body_template', posts: posts_raw, term: term),
          skip_validations: true
        )
      else
        post = SystemMessage.create_from_system_user(user, :saved_searches_notification, posts: posts_raw, term: term)
        topic = post.topic
        topic.custom_fields[custom_field_name(user)] = term
        topic.save
        post
      end
    end

    def custom_field_name(user)
      "pm_saved_search_results_#{user.id}"
    end
  end
end
