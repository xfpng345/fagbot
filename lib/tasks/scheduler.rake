desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'mechanize'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  agent = Mechanize.new
  url = agent.get("https://money.cnn.com/data/fear-and-greed/")
  elements = url.search("#needleChart li").inner_text
  # #htmlデータをパース
  # ul = open( url ).read.toutf8
  # doc = REXML::Document.new(ul)
  #メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: elements
  }
  response = client.multicast(user_ids, message)
  "OK"
end

task sunglasses: :environment do
  Sunglasses.sunglasses_main
end