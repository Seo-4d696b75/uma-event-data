# データの更新
# 更新ファイル： src/event.json src/icon.json icon/*

require 'net/http'
require 'json'

def get_http(uri)
  response = Net::HTTP.get_response(uri)
  return response.body if response.code == '200'

  puts "network error uri:#{uri} code:#{response.code}"
  nil
end

def get_imgs(list)
  list.each do |d|
    name = d['i']
    uri = URI.parse("https://img.gamewith.jp/article_tools/uma-musume/gacha/#{name}")
    img = get_http(uri)
    File.open("./icon/#{name}", 'wb') { |f| f.write(img) }
  end
end

def read_json_key_value_pair(str)
  m = /\A\s*'(?<key>[^']+)'\s*:/.match(str)
  return nil unless m

  key = m[:key]
  str = str[m.end(0)..]
  value, str = read_json_element(str)
  [key, value, str]
end

def read_json_element(str)
  if (m = /\A\s*\[/.match(str))
    # array
    str = str[m.end(0)..]
    list = []
    while true
      m = /\A\s*\]\s*,?/.match(str)
      break if m

      value, str = read_json_element(str)
      list << value
    end
    str = str[m.end(0)..]
    [list, str]
  elsif (m = /\A\s*\{/.match(str))
    # object
    str = str[m.end(0)..]
    obj = {}
    loop do
      m = /\A\s*\}\s*,?/.match(str)
      break if m

      key, value, str = read_json_key_value_pair(str)
      obj[key] = value
    end
    str = str[m.end(0)..]
    [obj, str]
  elsif (m = /\A\s*'(?<value>.*?)(?<!\\)'\s*,?/.match(str))
    # string
    value = m[:value].gsub("\\'", "'") # escape
    str = str[m.end(0)..]
    [value, str]
  elsif (m = /\A\s*(?<value>[0-9]+)\s*,?/.match(str))
    # int
    value = m[:vlaue].to_i
    str = str[m.end(0)..]
    [value, str]
  else
    raise 'json element not found'
  end
end

# JSONライクな文字列を変換する
# - 文字列はシングルクォーテーション
# - 値は文字列・整数値のみ
# - 末端のカンマも許す
def convert_json(str)
  read_json_element(str.force_encoding('utf-8'))[0]
end

# update data.json
res = get_http(URI.parse('https://gamewith-tool.s3-ap-northeast-1.amazonaws.com/uma-musume/female_event_datas.js'))
m = /window.eventDatas\[.+?\]\s?=\s?(?<events>\[.+\]);/m.match(res)
data = convert_json(m[:events])
File.open('src/event.json', 'w') do |f|
  f.write(JSON.pretty_generate(data))
end

# update icon.json
res = get_http(URI.parse('https://gamewith-tool.s3-ap-northeast-1.amazonaws.com/uma-musume/common_event_datas.js'))
m = /const imageDatas\s*=\s*(?<data>\{.+\};)/m.match(res)
data = convert_json(m[:data])
File.open('src/icon.json', 'w') do |f|
  f.write(JSON.pretty_generate(data))
end

# update icon/*.png
get_imgs(data['support'])
get_imgs(data['chara'])
