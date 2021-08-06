# frozen_string_literal: true

module UserNotificationsExtensions
  def saved_search(user, opts = {})
    saved_search = SavedSearch.find_by(id: opts[:notification_data_hash][:saved_search_id])
    return if saved_search.blank?

    build_email(
      user.email,
      template: "user_notifications.saved_search",
      locale: user_locale(user),
      topic_title: opts[:notification_data_hash][:topic_title],
      saved_search_query: saved_search.query,
      post_url: opts[:post].full_url,
    )
  end
end
