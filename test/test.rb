require 'mechanize'

agent = Mechanize.new
url = agent.get("https://money.cnn.com/data/fear-and-greed/")
now = url.search("#needleChart li").children[0].inner_text
close = url.search("#needleChart li").children[1].inner_text
week = url.search("#needleChart li").children[2].inner_text
month = url.search("#needleChart li").children[3].inner_text
year = url.search("#needleChart li").children[4].inner_text
all = url.search("#needleChart li").inner_text
agent2 = Mechanize.new
url2 = agent2.get("https://www.bloomberg.co.jp/quote/SPXL:US")
spxl = url2.search(".price").inner_text
message = "本日のSPXLは#{spxl}US$です。\n#{now}\n#{close}\n#{week}\n#{month}\n#{year}"

puts message