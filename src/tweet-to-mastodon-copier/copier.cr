require "http/client"
require "tempfile"

module TweetToMastodonCopier
  class Copier
    COPY_BUF_SIZE = 1024 * 1024
    VIDEO_UPLOAD_LIMIT = 64 * 1024 * 1024

    @target_mastodon : ::Mastodon::REST::Client

    def initialize(target_mastodon)
      @target_mastodon = target_mastodon
    end

    def process(tweet)
      text = tweet.text.gsub(%r{https://t.co.+$},"").strip

      attachments = process_media(tweet)

      @target_mastodon.create_status(status: text,
                                     media_ids: attachments.map(&.id))
    end

    private def process_media(tweet)
      blank = [] of ::Mastodon::Entities::Attachment
      extended_entities = tweet.extended_entities
      return blank if extended_entities.nil?
      media = extended_entities.media
      return blank if media.nil?

      media.map do |medium|
        pp medium.type

        case medium.type
        when "video"
          process_video(medium)
        when "photo"
          process_photo(medium)
        else
          nil
        end
      end.compact
    end

    private def process_photo(photo)
      url = photo.media_url_https + ":large"

      pp url

      upload(url)
    end

    private def process_video(video)
      video_info = video.video_info
      return nil if video_info.nil?

      seconds = (video_info.duration_millis / 1000) + 1

      best_variant = video_info.variants.reduce do |best, current|
        bst_br = best.bitrate
        next current if bst_br.nil?
        cur_br = current.bitrate
        next best if cur_br.nil?

        next best if (cur_br * seconds) > VIDEO_UPLOAD_LIMIT

        next current if cur_br > bst_br

        best
      end

      pp best_variant

      upload(best_variant.url)
    end

    private def upload(url)
      pp url
      filename_match = /(\w+\.\w\w\w):?[\w?=]*$/.match(url)
      pp filename_match
      return nil unless filename_match && filename_match[1].is_a? String
      filename = filename_match[1]
      media_attachment = nil
      Tempfile.open(filename) do |temp|
        pp temp.path
        HTTP::Client.get url do |resp|

          status = resp.status_code
          unless (status >= 200) && (status <= 299)
            temp.close
            temp.unlink
            return nil
          end

          buf = Bytes.new COPY_BUF_SIZE

          reader = resp.body_io

          while 0 != (got = reader.read(buf))
            temp.write buf[0, got]
          end

          temp.close
        end

        media_attachment = @target_mastodon.media_upload temp.path

        temp.unlink

      end

      pp media_attachment

      return media_attachment
    end
  end
end
