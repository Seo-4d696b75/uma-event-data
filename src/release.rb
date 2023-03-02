require 'json'
require 'date'
require 'set'

def read_json(path)
  str = ''
  File.open(path, 'r:utf-8') do |f|
    f.each_line do |line|
      str << line
    end
  end
  JSON.parse(str)
end

def assert(condition, message = '')
  return if condition

  puts message
  exit(1)
end

def check_name(name)
  n = name.gsub(/\s+/, '')
  puts "名前にカタカナ以外が含まれます：#{name}" unless n.match(/^[\p{Katakana}ー]+$/)
  n
end

old_data = read_json('data.json')
old_owner = old_data['owner']
ids = Set.new
max_id = (old_owner['chara'] + old_owner['support']).map do |e|
  assert !ids.member?(e['id']), "id duplicated #{JSON.dump(e)}"
  ids.add(e['id'])
  e['id']
end.max

scenario = ['共通']
old_data['event'].map { |e| e['owner'] }.select { |o| o['type'] == 'scenario' }.each do |o|
  name = o['name']
  unless scenario.include?(name)
    scenario << name
    puts "existing scenario #{name}"
  end
end

owner = read_json('src/icon.json')
owner['chara'].map! do |c|
  name = check_name(c['n'])
  i = c['i']
  list = [i]
  second = "#{File.basename(i, '.png')}_e.png"
  list << second if File.exist?("icon/#{second}")

  idx = old_owner['chara'].index { |e| e['name'] == name }
  id = max_id + 1
  if idx
    id = old_owner['chara'].delete_at(idx)['id']
  else
    puts "new chara detected #{JSON.dump(c)}"
    max_id += 1
  end

  {
    'id' => id,
    'name' => name,
    'icon' => list
  }
end
assert old_owner['chara'].empty?, "chara not found #{JSON.dump(old_owner['chara'])}"

owner['support'].map! do |s|
  name = check_name(s['n'])
  type = s['l'][0..1]
  rarity = s['l'].match(/S{0,2}R/)[0]
  idx = old_owner['support'].index do |e|
    e['name'] == name && e['type'] == type && e['rarity'] == rarity
  end
  id = max_id + 1
  if idx
    id = old_owner['support'].delete_at(idx)['id']
  else
    puts "new support detected #{JSON.dump(s)}"
    max_id += 1
  end

  {
    'id' => id,
    'name' => name,
    'icon' => s['i'],
    'type' => type,
    'rarity' => rarity
  }
end
assert old_owner['support'].empty?, "support not found #{JSON.dump(old_owner['support'])}"

event = read_json('src/event.json').map do |e|
  name = e['n']
  cls = e['c']
  owner_id = nil
  owner_type = nil
  if cls == 'm' || name == '共通'
    # イベント所有者なし
    unless scenario.include?(name)
      puts "new scenario detected #{name}"
      scenario << name
    end
    puts "scenario #{name} (event name:#{e['e']})"
    owner_type = 'scenario'
  elsif cls == 'c'
    # 育成キャラ
    name = check_name(name)
    o = owner['chara'].find { |c| c['name'] == name }
    owner_type = 'chara'
    owner_id = o['id']
  elsif cls == 's'
    # サポートカード
    name = check_name(name)
    type = e['l'][0..1]
    rarity = e['l'].match(/S{0,2}R/)[0]
    o = owner['support'].find do |s|
      s['name'] == name && s['type'] == type && s['rarity'] == rarity
    end
    owner_type = 'support'
    owner_id = o['id']
  else
    assert false, "invalid event type 'e' #{JSON.dump(e)}"
  end
  o = {
    'type' => owner_type,
    'name' => name
  }
  o['id'] = owner_id if owner_id
  {
    'title' => e['e'],
    'title_kana' => e['k'],
    'owner' => o,
    'choices' => e['choices'].map do |c|
      {
        'name' => c['n'],
        'message' => c['t']
      }
    end
  }
end

data = {
  'event' => event,
  'owner' => owner
}

File.open('data.json', 'w') do |file|
  file.write(JSON.pretty_generate(data))
end

size = File.size('data.json')
d = Date.today
v = d.year * 10_000 + d.month * 100 + d.day

info = {
  'version' => v,
  'size' => size
}

File.open('info.json', 'w') do |file|
  file.write(JSON.pretty_generate(info))
end
