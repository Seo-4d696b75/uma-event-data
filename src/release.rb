require 'json'
require 'date'

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

owner = read_json('src/icon.json')
idx = 0
owner['chara'].map! do |c|
  i = c['i']
  list = [i]
  second = "#{File.basename(i, '.png')}_e.png"
  list << second if File.exist?("icon/#{second}")

  {
    'id' => (idx += 1),
    'name' => c['n'],
    'icon' => list
  }
end
owner['support'].map! do |s|
  {
    'id' => (idx += 1),
    'name' => s['n'],
    'icon' => s['i'],
    'type' => s['l'][0..1],
    'rearity' => s['l'].match(/S{0,2}R/)[0]
  }
end

data = {
  'event' => event,
  'owner' => owner,
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
