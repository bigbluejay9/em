require "tmpdir"

task default: :build

task test: :build do
  sh "crystal spec"
end

task build: ["bin/em"]

FileList['src/*.cr'].each do |f|
  file "bin/em" => f
end

file "bin/em" do
  sh "shards build em"
end

task run: :build do
  sh "crystal run src/em.cr"
end

task :clean do
  sh "shards prune"
  sh "rm src/generated_emoji_data.cr"
  sh "rm -rf bin/ lib/ docs/ .shards/"
end

task install: :build do
  if `whoami`.strip == "root"
    puts "Do not run `rake install` as root"
    exit 1
  end

  sh "sudo cp bin/em /usr/local/bin/em"
  sh "sudo chmod 755 /usr/local/bin/em"
end

#emoji_data = {
#  "emoji-data.txt" =>
#    "https://www.unicode.org/Public/13.0.0/ucd/emoji/emoji-data.txt",
#  "emoji-variation-sequences.txt" =>
#    "https://www.unicode.org/Public/13.0.0/ucd/emoji/emoji-variation-sequences.txt",
#  "emoji-sequences.txt" =>
#    "https://www.unicode.org/Public/emoji/13.0/emoji-sequences.txt",
#  "emoji-zwj-sequences.txt" =>
#    "https://www.unicode.org/Public/emoji/13.0/emoji-zwj-sequences.txt",
#  "emoji-test.txt" =>
#    "https://www.unicode.org/Public/emoji/13.0/emoji-test.txt",
#}
#
#emoji_data.each do |file_name, source|
#  file "unicode-data/#{file_name}" do |t|
#    sh "curl -s #{source} -o #{t.name}"
#  end
#  task build: "unicode-data/#{file_name}"
#end
