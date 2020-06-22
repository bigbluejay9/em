require "option_parser"
require "xml"
require "log"

module Em
  VERSION = "0.1.0"

  BANNER = <<-BANNER
    Usage: em [<flags>...] [search terms]

    Search terms is one or more words describing an emoji.

    Example:
      $ em hot face
      🥵
      $ em rolling on the floor
      🤣

    Flags
  BANNER

  VERSION_INFO = <<-VERSION_INFO
  em - Emoji Finder 😄
  v#{VERSION}
  VERSION_INFO

  MAX_RESULTS = 10
end

include Em

Log.setup_from_env

terms = [] of String

OptionParser.parse do |parser|
  parser.banner = BANNER

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.on("-v", "--version", "Show version") do
    puts VERSION_INFO
    exit
  end

  parser.unknown_args do |a, _|
    if a.empty?
      STDERR.puts parser
      exit 1
    end
    terms = a
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit 1
  end
end

def to_pb(text : String) : Bool
  puts "Copied #{text} to pasteboard."
  process = Process.new("pbcopy", input: Process::Redirect::Pipe)
  process.input.print(text)
  process.input.close
  process.wait.success?
end

class EmojiData
  property descriptions = Set(String).new
  property tts : String?
  property unicode_properties = [] of Symbol
end

# Parse CLDR Data
emojis = {} of String => EmojiData
XML.parse(File.read("unicode-data/en.xml")).
  xpath_node("//ldml/annotations").not_nil!.
  children.select(&.element?).each do |a|
    codepoint = a["cp"]
    data = emojis[codepoint]? || EmojiData.new

    if a["type"]? == "tts"
      data.tts = a.content
    end
    data.descriptions.concat(
      a.content.split("|", remove_empty: true).map(&.strip.downcase))

    unless emojis.has_key?(codepoint)
      emojis[codepoint] = data
    end
end

full_search = terms.join(" ")

results = emojis.select do |char, d|
  d.descriptions.includes?(full_search) ||
    d.tts.try &.downcase.includes?(full_search)
end.to_a

puts "Search term '#{full_search}'"
if results.empty?
  puts "No emoji matches ☹️"
  exit 1
end

if results.size == 1
  to_pb(results.first.first)
  exit
end

if results.size > MAX_RESULTS
  puts "#{results.size} matches - trimmed to #{MAX_RESULTS} results"
  results = results.first(MAX_RESULTS)
end

results.each_with_index do |em, i|
  puts "#{i + 1}: #{em.first} - #{em[1].descriptions.join(" | ")}"
end
puts "0: Exit"

loop do
  print "Which emoji to copy [1]: "
  if input = gets
    if choice = input.to_i?
      exit 0 if choice == 0

      if em = results[choice - 1]?
        to_pb(em.first)
        exit 0
      end
      puts "Bad input: '#{input}'"
    end
  else
    exit 0
  end
end
