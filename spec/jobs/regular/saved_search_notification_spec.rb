# frozen_string_literal: true

require 'rails_helper'

describe Jobs::SavedSearchNotification do
  let!(:user) { Fabricate(:user, trust_level: 1) }

  before do
    SearchIndexer.enable
    SiteSetting.saved_searches_enabled = true
  end

  it "does nothing if user has no saved searches" do
    expect { described_class.new.execute(user_id: user.id) }
      .to_not change { Topic.count }
  end

  context "with saved searches" do
    before do
      SavedSearch.create!(user: user, query: "coupon")
      SavedSearch.create!(user: user, query: "discount")
    end

    it "does not create a PM for the user if no results are found" do
      expect { described_class.new.execute(user_id: user.id) }
        .to_not change { Topic.count }
    end

    context "with recent post" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.") }

      it "creates a PM if recent results are found" do
        expect { described_class.new.execute(user_id: user.id) }
          .to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(1)
      end

      it "creates a PM for each search term" do
        post2 = Fabricate(:post, raw: "An exclusive discount just for you cool people.")
        expect { described_class.new.execute(user_id: user.id) }
          .to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(2)
      end

      it "does nothing if trust level is too low" do
        SiteSetting.saved_searches_min_trust_level = 2
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end

      it "does not notify suspended users" do
        user.update!(suspended_at: 1.hour.ago, suspended_till: 20.years.from_now)
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end

      it "does not notify deactivated users" do
        user.deactivate(Fabricate(:admin))
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end

      it "does not notify for small actions" do
        Fabricate(:post, topic: post.topic, raw: "Moved this to coupon category.", post_type: Post.types[:small_action])
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end
    end

    context "with old posts" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.", created_at: 1.day.ago) }

      it "does not create a PM if results are too old" do
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end
    end

    context "with own posts" do
      let!(:post) { Fabricate(:post, user: user, raw: "Check out these coupon codes for cool things.") }

      it "does not notify for my own posts" do
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.count }
      end
    end

    context "not the first search" do
      let!(:post) { Fabricate(:post, raw: "Check out these coupon codes for cool things.") }

      before do
        described_class.new.execute(user_id: user.id)
      end

      it "does not notify about the same search results" do
        expect { described_class.new.execute(user_id: user.id) }
          .to_not change { Topic.where(subtype: TopicSubtype.system_message).count }
      end

      it "notifies about new result in the same topic" do
        Fabricate(:post, raw: "Everyone loves a good coupon I think.")
        expect { described_class.new.execute(user_id: user.id) }
          .to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(0)
          .and change { Topic.find_by(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'coupon')).posts.size }.by(1)
      end

      it "creates a new topic if it is for a different search term" do
        Fabricate(:post, raw: "Everyone loves a good discount I think.")
        expect { described_class.new.execute(user_id: user.id) }
          .to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(1)
          .and change { Topic.find_by(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'coupon')).posts.size }.by(0)
      end

      it "creates a new topic if the previous one was deleted" do
        Topic.find_by(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'coupon')).trash!

        Fabricate(:post, raw: "Everyone loves a good coupon I think.")
        expect { described_class.new.execute(user_id: user.id) }
          .to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(1)
      end
    end
  end
end
