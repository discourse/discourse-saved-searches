# frozen_string_literal: true

describe SavedSearches::SavedSearchesController do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }

  before { SiteSetting.saved_searches_enabled = true }

  describe "#update" do
    it "does not work when not logged in" do
      put "/u/#{user.username}/preferences/saved-searches.json"
      expect(response.status).to eq(403)
    end

    it "can create and update saved searches" do
      saved_search =
        Fabricate(
          :saved_search,
          user: user,
          query: "discount",
          frequency: SavedSearch.frequencies[:daily],
        )
      sign_in(user)

      put "/u/#{user.username}/preferences/saved-searches.json",
          params: {
            searches: {
              0 => {
                query: "discount",
                frequency: "weekly",
              },
              1 => {
                query: "discourse",
                frequency: "immediately",
              },
            },
          }

      expect(response.status).to eq(200)
      expect(user.saved_searches.size).to eq(2)

      expect(saved_search.reload.query).to eq("discount")
      expect(saved_search.frequency).to eq(SavedSearch.frequencies[:weekly])

      new_saved_search = user.saved_searches.last
      expect(new_saved_search.query).to eq("discourse")
      expect(new_saved_search.frequency).to eq(SavedSearch.frequencies[:immediately])
    end

    it "can delete all saved searches" do
      Fabricate(:saved_search, user: user)
      sign_in(user)

      put "/u/#{user.username}/preferences/saved-searches.json"
      expect(response.status).to eq(200)
      expect(user.saved_searches.size).to eq(0)
    end
  end
end
