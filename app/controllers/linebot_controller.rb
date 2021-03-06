class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'mechanize'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      # ユーザーのメッセージによって返信を分ける
      when Line::Bot::Event::Message
        case event.type
          when Line::Bot::Event::MessageType::Text
            # fear & greedを取得
            agent = Mechanize.new
            url = agent.get("https://money.cnn.com/data/fear-and-greed/")
            now = url.search("#needleChart li").children[0].inner_text
            close = url.search("#needleChart li").children[1].inner_text
            week = url.search("#needleChart li").children[2].inner_text
            month = url.search("#needleChart li").children[3].inner_text
            year = url.search("#needleChart li").children[4].inner_text
            # spxlを取得
            agent2 = Mechanize.new
            url2 = agent2.get("https://www.bloomberg.co.jp/quote/SPXL:US")
            spxl = url2.search(".price").inner_text
            fagLink = "https://money.cnn.com/data/fear-and-greed/"
            spxlLink = "https://www.bloomberg.co.jp/quote/SPXL:US"
            reply = "本日のSPXLは#{spxl}US$です。\n#{now}\n#{close}\n#{week}\n#{month}\n#{year}\n#{fagLink}\n#{spxlLink}"
            input = event.message['text']
          case input
          when /.*(今|いま|now).*/
            message = {
              type: 'text',
              text: now
            }
          when /.*(最近|さいきん|close).*/
            message = {
              type: 'text',
              text: close
            }
          when /.*(週|しゅう|week).*/
            message = {
              type: 'text',
              text: week
            }
          when /.*(月|つき|month).*/
            message = {
              type: 'text',
              text: month
            }
          when /.*(年|ねん|year).*/
            message = {
              type: 'text',
              text: year
            }
          when input
            message = {
              type: 'text',
              text: reply
            }
          end
          client.reply_message(event['replyToken'], message)
        end
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        line_id = event['source']['userId']
        User.create(line_id: line_id)
      # LINEお友達解除された場合
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

end
