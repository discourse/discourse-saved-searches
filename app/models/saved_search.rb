# frozen_string_literal: true

class SavedSearch < ActiveRecord::Base
  belongs_to :user

  has_many :saved_search_results

  after_save :compile_query

  def compile_query
    search = Search.new(query, guardian: user.guardian)
    if search.term.present?
      self.class
        .where(id: self.id)
        .update_all("compiled_query = #{Search.ts_query(term: search.term)}")
    else
      self.update_column(:compiled_query, nil)
    end
  end
end

# == Schema Information
#
# Table name: saved_searches
#
#  id             :bigint           not null, primary key
#  user_id        :integer
#  query          :string           not null
#  compiled_query :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_saved_searches_on_user_id  (user_id)
#
