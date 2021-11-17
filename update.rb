require "net/http"
require "json"

def get_http(uri)
  response = Net::HTTP.get_response(uri)
  if response.code == "200"
    return response.body
  else
    puts "network error uri:#{uri} code:#{response.code}"
    return nil
  end
end

def read_json_key_value_pair(str)
  m = /\A\s*'(?<key>[^']+)'\s*:/.match(str)
  return nil if !m
  key = m[:key]
  str = str[m.end(0)..-1]
  value, str = read_json_element(str)
  return [key, value, str]
end

def read_json_element(str)
  if m = /\A\s*\[/.match(str)
    # array
    str = str[m.end(0)..-1]
    list = []
    while true
      m = /\A\s*\]\s*,?/.match(str)
      break if m
      value, str = read_json_element(str)
      list << value
    end
    str = str[m.end(0)..-1]
    return [list, str]
  elsif m = /\A\s*\{/.match(str)
    # object
    str = str[m.end(0)..-1]
    obj = {}
    while true
      m = /\A\s*\}\s*,?/.match(str)
      break if m
      key, value, str = read_json_key_value_pair(str)
      obj[key] = value
    end
    str = str[m.end(0)..-1]
    return [obj, str]
  elsif m = /\A\s*'(?<value>.*?)(?<!\\)'\s*,?/.match(str)
    # string
    value = m[:value].gsub("\\'", "'") # escape
    str = str[m.end(0)..-1]
    return [value, str]
  elsif m = /\A\s*(?<value>[0-9]+)\s*,?/.match(str)
    # int
    value = m[:vlaue].to_i
    str = str[m.end(0)..-1]
    return [value, str]
  else
    raise "json element not found"
  end
end

# JSONライクな文字列を変換する
# - 文字列はシングルクォーテーション
# - 値は文字列・整数値のみ
# - 末端のカンマも許す
def convert_json(str)
  read_json_element(str.force_encoding("utf-8"))[0]
end

def convert_quote(str)
  str = str.gsub('"', '\\"')
  str = str.gsub('\'', '"')
  str = str.gsub(/\},\]\},/, "}]},")
  str = str.sub(/,\s*\]\s*\z/, "]")
  return str
end

# update data.json
res = get_http(URI.parse("https://gamewith-tool.s3-ap-northeast-1.amazonaws.com/uma-musume/female_event_datas.js"))
m = /window.eventDatas\[.+?\]\s?=\s?(?<events>\[.+\]);/m.match(res)
#data = convert_json(m[:events])
data = JSON.parse(convert_quote(m[:events]))
File.open("hoge.json", "w") do |f|
  f.write(JSON.pretty_generate(data))
end
