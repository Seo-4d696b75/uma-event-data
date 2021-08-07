require "json"
require "date"

def read_json(path)
  str = ""
  File.open(path, "r:utf-8") do |f|
    f.each_line do |line|
      str << line
    end
  end
  JSON.parse(str)
end

event = read_json("event.json").map do |e|
  {
    "title" => e["e"],
    "title_kana" => e["k"],
    "owner" => e["n"],
    "choices" => e["choices"].map do |c|
      {
        "name" => c["n"],
        "message" => c["t"],
      }
    end,
  }
end

owner = read_json("icon.json")
owner["support"].map! do |s|
  {
    "name" => s["n"],
    "type" => s["l"],
    "icon" => s["i"],
  }
end
owner["chara"].map! do |c|
  i = c["i"]
  list = [i]
  second = "#{File.basename(i, ".png")}_e.png"
  if File.exists?("icon/#{second}")
    list << second
  end
  {
    "name" => c["n"],
    "icon" => list,
  }
end

data = {
  "event" => event,
  "owner" => owner,
}

File.open("data.json", "w") do |file|
  file.write(JSON.pretty_generate(data))
end

size = File.size("data.json")
d = Date.today
v = d.year * 10000 + d.month * 100 + d.day

info = {
  "version" => v,
  "size" => size,
}

File.open("info.json", "w") do |file|
  file.write(JSON.pretty_generate(info))
end
