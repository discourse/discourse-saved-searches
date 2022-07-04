# frozen_string_literal: true

require 'rails_helper'

describe Jobs::ExecuteSavedSearches do
  subject(:job) { described_class.new }

  fab!(:user) { Fabricate(:user, trust_level: 1) }

  before do
    SearchIndexer.enable
    SiteSetting.saved_searches_enabled = true
  end

  it "does nothing if user has no saved searches" do
    expect { job.execute(user_id: user.id) }
      .to_not change { Topic.count }
  end

  context "with saved searches" do
    fab!(:saved_search_1) { Fabricate(:saved_search, user: user, query: "coupon") }
    fab!(:saved_search_2) { Fabricate(:saved_search, user: user, query: "discount") }

    it "does not create a notification for the user if no results are found" do
      expect { job.execute(user_id: user.id) }
        .to_not change { Topic.count }
    end

    it "send notification email" do
      Jobs.run_immediately!
      NotificationEmailer.enable
      post = Fabricate(:post, raw: "Check out these coupon codes for cool things.")

      expect { job.execute(user_id: user.id) }
        .to change { Notification.count }.by(1)
        .and change { ActionMailer::Base.deliveries.size }.by(1)

      expect(ActionMailer::Base.deliveries.first.subject).to include("New Saved Search Result")
      expect(ActionMailer::Base.deliveries.first.subject).to include(post.topic.title)
      expect(ActionMailer::Base.deliveries.first.body).to include("coupon")
      expect(ActionMailer::Base.deliveries.first.body).to include(post.full_url)
    end

    context "with recent post" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.") }

      it "creates a notification if recent results are found" do
        expect { job.execute(user_id: user.id) }
          .to change { Notification.count }.by(1)
      end

      it "creates a notification for each result" do
        Fabricate(:post, raw: "An exclusive coupon just for you cool people.")
        Fabricate(:post, raw: "An exclusive discount just for you cool people.")

        expect { job.execute(user_id: user.id) }
          .to change { Notification.count }.by(3)
      end

      it "does nothing if trust level is too low" do
        SiteSetting.saved_searches_min_trust_level = 2

        expect { job.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end

      it "does not notify suspended users" do
        user.update!(suspended_at: 1.hour.ago, suspended_till: 20.years.from_now)

        expect { job.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end

      it "does not notify deactivated users" do
        user.deactivate(Fabricate(:admin))

        expect { job.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end

      it "does not notify for small actions" do
        Fabricate(:post, topic: post.topic, raw: "Moved this to coupon category.", post_type: Post.types[:small_action])

        expect { job.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end
    end

    context "with old posts" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.", created_at: 1.day.ago) }

      it "does not create a notification if results are too old" do
        expect { job.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end
    end

    context "with own posts" do
      let!(:post) { Fabricate(:post, user: user, raw: "Check out these coupon codes for cool things.") }

      it "does not notify for my own posts" do
        expect { job.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end
    end

    context "not the first search" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.") }

      before do
        job.execute(user_id: user.id)
      end

      it "does not notify about the same search results" do
        expect { job.execute(user_id: user.id) }
          .to_not change { Notification.count }
      end

      it "notifies about new results" do
        Fabricate(:post, raw: "An exclusive coupon just for you cool people.")
        Fabricate(:post, raw: "An exclusive discount just for you cool people.", topic: post.topic)

        expect { job.execute(user_id: user.id) }
          .to change { Notification.count }.by(2)
      end
    end

    context "with daily digests" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.") }

      before do
        SavedSearch.update_all(last_searched_at: 1.day.ago, frequency: SavedSearch.frequencies[:daily])
      end

      it "creates a notification if recent results are found" do
        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(1)
      end

      it "creates a notification for each result" do
        Fabricate(:post, raw: "An exclusive coupon just for you cool people.")
        Fabricate(:post, raw: "Another exclusive coupon just for you cool people.")
        Fabricate(:post, raw: "An exclusive discount just for you cool people.")

        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(2)
      end

      it "does not create a new topic if one exists" do
        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(1)

        Fabricate(:post, raw: "An exclusive coupon just for you cool people.")
        SavedSearch.update_all(last_searched_at: 1.day.ago)

        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(0)
          .and change { Post.count }.by(1)
      end

      it "does not create a new topic if not enough time passed" do
        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(1)

        Fabricate(:post, raw: "An exclusive coupon just for you cool people.")

        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(0)
          .and change { Post.count }.by(0)

        SavedSearch.update_all(last_searched_at: 1.day.ago)

        expect { job.execute(user_id: user.id) }
          .to change { Topic.count }.by(0)
          .and change { Post.count }.by(1)
      end

      context "when topic has been trashed" do
        before do
          job.execute(user_id: user.id)
          Topic.last.trash!
          Fabricate(:post, raw: "An exclusive coupon just for you cool people.")
          SavedSearch.update_all(last_searched_at: 1.day.ago)
        end

        it "creates a new topic" do
          expect { job.execute(user_id: user.id) }.to change { Topic.count }.by(1)
        end
      end
    end
  end
end
