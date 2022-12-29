# frozen_string_literal: true

require "rails_helper"

describe Jobs::ScheduleSavedSearches do
  fab!(:saved_search_1) { Fabricate(:saved_search) }
  fab!(:saved_search_2) { Fabricate(:saved_search) }

  it "schedules one job per saved search" do
    expect { described_class.new.execute({}) }.to change {
      Jobs::ExecuteSavedSearches.jobs.count
    }.by(2)
  end
end
