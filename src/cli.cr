require "option_parser"
require "xml"
require "log"
require "./emoji_data"

module Em
  VERSION = "1.1.0"

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

  DEFAULT_MAX_RESULTS = 10

  def self.fatal(text : String)
    STDERR.puts text
    exit 1
  end

  def self.to_pasteboard(text : String, verbose : Bool = true) : Bool
    puts "Copied #{text} to pasteboard." if verbose
    Process.run("pbcopy", input: IO::Memory.new(text)).success?
  end

  def self.parse_annotations(file : String)
    fatal("Cannot find Unicode CLDR EN data at #{file}. ") unless File.file?(file)

    # Parse CLDR Data
    emojis = {} of String => EmojiData
    XML.parse(File.read(file))
      .xpath_node("//ldml/annotations").not_nil!
      .children.select(&.element?).each do |a|
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
    puts emojis.to_s
  end

  def self.run
    Log.setup_from_env
    terms = [] of String
    max_results = DEFAULT_MAX_RESULTS
    cldr_data_file : String? = nil
    parser = OptionParser.parse do |parser|
      parser.banner = BANNER

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end

      parser.on("-v", "--version", "Show version") do
        puts VERSION_INFO
        exit
      end

      parser.on("-p FILE", "--parse=FILE", "Parse given CLDR data file.") do |f|
        cldr_data_file = f
      end

      parser.on("-n NUM", "--num_results=NUM",
        "Maximum of results to display. 0 to display all. Default 10") do |r|
        if i = r.to_i?
          if (0..).includes? i
            max_results = r.to_i
            next
          end
        end
        fatal("Flag -n/--num_results='#{r}': not a valid integer")
      end

      parser.unknown_args do |a, _|
        terms = a
      end

      parser.invalid_option do |flag|
        fatal("#{flag} is not a valid option.\n#{parser}")
      end

      parser.missing_option do |s|
        fatal("Missing flag option for #{s}.\n\n#{parser}")
      end
    end

    if f = cldr_data_file
      parse_annotations(f)
      exit
    end

    fatal(parser.to_s) if terms.empty?
    full_search = terms.join(" ")

    results = EMOJI_ANNOTATIONS_DATA.select do |char, d|
      d.descriptions.includes?(full_search) ||
        d.tts.try &.downcase.includes?(full_search)
    end.to_a

    puts "Search term '#{full_search}'"
    fatal("No emoji matches 😥") if results.empty?

    if results.size == 1
      to_pasteboard(results.first.first)
      exit
    end

    if max_results != 0 && results.size > max_results
      puts "#{results.size} matches - trimmed to #{max_results} results"
      results = results.first(max_results)
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
            to_pasteboard(em.first)
            exit 0
          end
          puts "Bad input: '#{input}'"
        end
      else
        exit 0
      end
    end
  end
end

Em.run
