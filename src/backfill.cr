require "crystweet"
require "mastodon"
require "./tweet-to-mastodon-copier/*"
require "dotenv"

 target_mastodon =
      ::Mastodon::REST::Client.new(
      access_token: "f52e7be62a0ad8b5980d63eedbf325f7493509af7997dbec21919e30f4f6e19f",
      url: "m.bonzoesc.net")

client = ::Twitter::Rest::Client.new("wDUA3Lh8fwzValGZkFrlcnAJn", "V1wnNcxP4jMWTlsoUYusM7hSsWX83DiszNSl3diB87W2gGGr3J", "7865582-dcFcYiTSN9HYxim52FcDiXUWlvfIuMtF0PeOEZuEcO", "gouDrRvLdnq1AyxTzxs9lqH5x9piyxMhxCPSAkbb3LW5B")

tw = client.get("https://api.twitter.com/1.1/statuses/show.json?id=#{ARGV[0]}")

tweet = Twitter::Response::TopLevelTweet.extended_new_while_streaming(JSON::PullParser.new(tw.body))

c = ::TweetToMastodonCopier::Copier.new(target_mastodon: target_mastodon)

c.process tweet
