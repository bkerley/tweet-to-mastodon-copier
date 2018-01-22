require "dotenv"
require "./tweet-to-mastodon-copier/*"

# TODO: Write documentation for `Tweet::To::Mastodon::Copier`
module TweetToMastodonCopier
  def self.main
    target_mastodon =
      ::Mastodon::REST::Client.new(
      access_token: ENV["MASTODON_TARGET_ACCESS_TOKEN"],
      url: ENV["MASTODON_SERVER"])

    twitter_streamer =
      TwitterFilter.new(consumer_key: ENV["TWITTER_CONSUMER_KEY"],
                        consumer_secret: ENV["TWITTER_CONSUMER_SECRET"],
                        access_key: ENV["TWITTER_ACCESS_KEY"],
                        access_secret: ENV["TWITTER_ACCESS_SECRET"],
                        user_id: ENV["TWITTER_USER"],
                        hashtag: ENV["TWITTER_HASHTAG"])

    copier =
      Copier.new(target_mastodon: target_mastodon)

    twitter_streamer.run! copier
  end
end

Dotenv.load

TweetToMastodonCopier.main
