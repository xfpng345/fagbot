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
      #おうむ返し
      when Line::Bot::Event::Message
        case event.type
            when Line::Bot::Event::MessageType::Text
            input = "a"#event.message['text']
            agent = Mechanize.new
            url = agent.get("https://money.cnn.com/data/fear-and-greed/")
            elements = url.search("#needleChart li")
            message = {
              type: 'text',
              text: input
            }
            client.reply_message(event['replyToken'], message)
          end
        # ユーザーからテキスト形式のメッセージが送られて来た場合
        # when Line::Bot::Event::MessageType::Text
        #   input = event.message["text"]
        #   agent = Mechanize.new
        #   url = agent.get("https://money.cnn.com/data/fear-and-greed/")
        #   elements = url.search("#needleChart li")
        #   day = ["今","最近","一週間前","１ヶ月前","１年前"]
        # case input
        #   when /.*(明日|あした).*/
        #     message = {
        #       type: 'text',
        #       text: elements
        #     }
        #     client.reply_message(event['replyToken'], message)
        # end
        # LINEお友達追された場合
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
