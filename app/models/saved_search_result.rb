# frozen_string_literal: true

class SavedSearchResult < ActiveRecord::Base
  belongs_to :saved_search
  belongs_to :post
  belongs_to :notification
end

# == Schema Information
#
# Table name: saved_search_results
#
#  id              :bigint           not null, primary key
#  saved_search_id :integer          not null
#  post_id         :integer          not null
#  notification_id :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_saved_search_results_on_post_id  (post_id)
#
