# frozen_string_literal: true

require "rails_helper"

describe Jobs::ScheduleSavedSearches do
  fab!(:saved_search_1) { Fabricate(:saved_search) }
  fab!(:saved_search_2) { Fabricate(:saved_search) }

  context "when plugin is enabled" do
    before { SiteSetting.saved_searches_enabled = true }

    it "schedules one job per saved search" do
      expect { described_class.new.execute({}) }.to change {
        Jobs::ExecuteSavedSearches.jobs.count
      }.by(2)
    end
  end

  context "when plugin is disabled" do
    it "schedules one job per saved search" do
      expect { described_class.new.execute({}) }.not_to change {
        Jobs::ExecuteSavedSearches.jobs.count
      }
    end
  end
end
