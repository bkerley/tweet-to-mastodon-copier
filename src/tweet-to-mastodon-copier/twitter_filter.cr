require "crystweet"

module TweetToMastodonCopier
  class TwitterFilter
    @user_id : UInt64
    
    def initialize(consumer_key : String, consumer_secret : String,
                   access_key : String, access_secret : String,
                   user_id : String, hashtag : String)
      @client = ::Twitter::Stream::Client.new(
        consumer_key, consumer_secret,
        access_key, access_secret)

      @user_id = user_id.to_u64
      @hashtag = hashtag
    end

    def run!(processor)
      @client.stream follow: [@user_id] do |tweet|
        next unless tweet.entities.hashtags.any? {|ht| @hashtag == ht.text}

        pp tweet
        
        processor.process tweet
      end
    end
  end
end
