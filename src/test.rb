require 'minitest/autorun'
require 'json'

def read_json(path)
  str = ''
  File.open(path, 'r:utf-8') do |f|
    f.each_line do |line|
      str << line
    end
  end
  JSON.parse(str)
end

## データのテスト
## release.rbで整形する前のrawデータ対象
class FormatTest < Minitest::Test
  def test_event
    events = read_json('src/event.json')
    events.each_with_index do |e, i|
      title = e['e']
      owner = e['n']
      kana = e['k']
      choices = e['choices']
      assert title.is_a?(String), "invalid title string at index #{i} in event.json"
      assert owner.is_a?(String), "invalid owner string at index #{i} in event.json"
      assert kana.is_a?(String), "invalid title kana string at index #{i} in event.json"
      assert choices.is_a?(Array), "invalid choices array at index #{i} in event.json"
      choices.each_with_index do |c, j|
        name = c['n']
        mes = c['t']
        assert name.is_a?(String), "invalid name string at index #{j} in event at index #{i} in event.json"
        assert mes.is_a?(String), "invalid mes string at index #{j} in event at index #{i} in event.json"
      end
    end
  end

  def test_icon
    data = read_json('src/icon.json')
    chara = data['chara']
    support = data['support']
    types = ['スピ', 'スタ', 'パワ', '根性', '賢さ', '友人', 'グル']
    assert chara.is_a?(Array), 'invalid "chara" array  in icon.json'
    assert support.is_a?(Array), 'invalid "support" array in icon.json'
    support.each_with_index do |s, i|
      name = s['n']
      icon = s['i']
      cls = s['c']
      type = s['l'][0..1]
      rarity = s['l'].match(/S{0,2}R/)
      assert name.is_a?(String), "invalid name string at index #{i} of support in icon.json"
      assert icon.is_a?(String), "invalid icon string at index #{i} of support in icon.json"
      assert cls == 's', "invalid class string at index #{i} of support in icon.json" # 「サポートカード」固定
      assert types.include?(type), "invalid type string at index #{i} of support in icon.json"
      assert rarity, "invalid rarity string at index #{i} of support in icon.json"
      assert File.exist?("icon/#{icon}"), "icon image not found: #{icon} at index #{i} of support in icon.json"
    end

    chara.each_with_index do |c, i|
      name = c['n']
      icon = c['i']
      cls = c['c']
      assert name.is_a?(String), "invalid name string at index #{i} of chara in icon.json"
      assert icon.is_a?(String), "invalid icon string at index #{i} of chara in icon.json"
      assert cls == 'c', "invalid class string at index #{i} of chara in icon.json" # 「サポートカード」固定
      assert File.exist?("icon/#{icon}"), "icon image not found: #{icon} at index #{i} of chara in icon.json"
    end
  end
end
