require "minitest/autorun"
require "json"

def read_json(path)
  str = ""
  File.open(path, "r:utf-8") do |f|
    f.each_line do |line|
      str << line
    end
  end
  JSON.parse(str)
end

class FormatTest < Minitest::Test
  def test_event
    events = read_json("event.json")
    events.each_with_index do |e, i|
      title = e["e"]
      owner = e["n"]
      kana = e["k"]
      choices = e["choices"]
      assert title.kind_of?(String), "invalid title string at index #{i} in event.json"
      assert owner.kind_of?(String), "invalid owner string at index #{i} in event.json"
      assert kana.kind_of?(String), "invalid title kana string at index #{i} in event.json"
      assert choices.kind_of?(Array), "invalid choices array at index #{i} in event.json"
      choices.each_with_index do |c, j|
        name = c["n"]
        mes = c["t"]
        assert name.kind_of?(String), "invalid name string at index #{j} in event at index #{i} in event.json"
        assert mes.kind_of?(String), "invalid mes string at index #{j} in event at index #{i} in event.json"
      end
    end
  end

  def test_icon
    data = read_json("icon.json")
    chara = data["chara"]
    support = data["support"]
    assert chara.kind_of?(Array), "invalid 'chara' array  in icon.json"
    assert support.kind_of?(Array), "invalid 'support' array in icon.json"
    support.each_with_index do |s, i|
      name = s["n"]
      type = s["l"]
      icon = s["i"]
      assert name.kind_of?(String), "invalid name string at index #{i} of support in icon.json"
      assert type.kind_of?(String), "invalid type string at index #{i} of support in icon.json"
      assert icon.kind_of?(String), "invalid icon string at index #{i} of support in icon.json"
      assert File.exists?("icon/#{icon}"), "icon image not found: #{icon} at index #{i} of support in icon.json"
    end

    chara.each_with_index do |c, i|
      name = c["n"]
      icon = c["i"]
      assert name.kind_of?(String), "invalid name string at index #{i} of chara in icon.json"
      assert icon.kind_of?(String), "invalid icon string at index #{i} of chara in icon.json"
      assert File.exists?("icon/#{icon}"), "icon image not found: #{icon} at index #{i} of chara in icon.json"
    end
  end
end
