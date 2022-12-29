# frozen_string_literal: true

class SavedSearch < ActiveRecord::Base
  belongs_to :user

  has_many :saved_search_results

  before_save :set_last_post_id
  before_save :set_last_searched_at
  after_save :compile_query

  def self.frequencies
    @frequencies ||= Enum.new(immediately: 0, hourly: 1, daily: 2, weekly: 3)
  end

  private

  def set_last_post_id
    self.last_post_id ||= Post.last&.id || 0
  end

  def set_last_searched_at
    self.last_searched_at ||= Time.zone.now
  end

  def compile_query
    if will_save_change_to_query? || self.compiled_query.blank?
      search = Search.new(query, guardian: user.guardian)
      if search.term.present?
        self
          .class
          .where(id: self.id)
          .update_all("compiled_query = #{Search.ts_query(term: search.term)}")
      else
        self.update_column(:compiled_query, nil)
      end
    end
  end
end

# == Schema Information
#
# Table name: saved_searches
#
#  id               :bigint           not null, primary key
#  user_id          :integer          not null
#  query            :string           not null
#  compiled_query   :string
#  last_post_id     :integer          not null
#  last_searched_at :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_saved_searches_on_user_id  (user_id)
#
