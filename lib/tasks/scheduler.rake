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
  #urlのサイトからfear&greed indexをスクレイピング
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
  
  #メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: reply
  }
  response = client.multicast(user_ids, message)
  "OK"
end

task sunglasses: :environment do
  Sunglasses.sunglasses_main
end