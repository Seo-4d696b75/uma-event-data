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

event = read_json('src/event.json').map do |e|
  {
    'title' => e['e'],
    'title_kana' => e['k'],
    'owner' => e['n'],
    'choices' => e['choices'].map do |c|
      {
        'name' => c['n'],
        'message' => c['t']
      }
    end
  }
end

def assert(condition, message='')
  return if condition

  puts message
  exit(1)
end

old_owner = read_json('data.json')['owner']
ids = Set.new
max_id = (old_owner['chara'] + old_owner['support']).map do |e|
  assert !ids.member?(e['id']), "id duplicated #{JSON.dump(e)}"
  ids.add(e['id'])
  e['id']
end.max

owner = read_json('src/icon.json')
owner['chara'].map! do |c|
  name = c['n']
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
assert old_owner['chara'].length.zero?, "chara not found #{JSON.dump(old_owner['chara'])}"

owner['support'].map! do |s|
  name = s['n']
  type = s['l'][0..1]
  rearity = s['l'].match(/S{0,2}R/)[0]
  idx = old_owner['support'].index do |e|
    e['name'] == name && e['type'] == type && e['rearity'] == rearity
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
    'rearity' => rearity
  }
end
assert old_owner['support'].length.zero?, "support not found #{JSON.dump(old_owner['support'])}"

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
