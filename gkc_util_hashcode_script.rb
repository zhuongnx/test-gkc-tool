#!/usr/bin/env ruby
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ./script.rb [HASH] [OPTIONS]'
  opts.on('-c', '--c FILE', 'configuration file') { |file|  options[:file_config] = file }

  opts.on('-f', '--f FILE', 'add hash to specific file') { |file|  options[:file] = file }

  opts.on('-l', '--language LANG', 'programming language') { |lang| options[:language] = lang }

  opts.on('-i', '--ignore FILE', 'ignore file') { |file| options[:ignore_files] = file }

  opts.on('-h', '--help', 'show this message, --help for more info') do
    puts opts
    exit
  end
end.parse!

if options[:file_config].nil? && ARGV.size < 1
  puts 'Please give me a string code'
  exit
end

hash_string, folder = ARGV[0], ARGV[1]

if options[:file_config]
  config = YAML.load_file(options[:file_config])
  folder = config["folder_path"]
  options[:ignore_files] = config["ignore_file_extensions"]
  options[:language] = config["language"]
  hash_string = config["hash_code_prefix"] + config["hash_code"]
end

def language_props(lang, hash_string)
  languages = {
    ruby: {
      cmt: "# #{hash_string}",
      ext: ".rb",
    },
    php: {
      cmt: "// #{hash_string}",
      ext: ".php",
    },
    java: {
      cmt: "/* #{hash_string} */",
      ext: ".java",
    },
    objectiveC: {
      cmt: "/* #{hash_string} */",
      ext: ".m",
    },
    html: {
      cmt: "<!-- #{hash_string} -->",
      ext: ".html",
    },
    css: {
      cmt: "/* #{hash_string} */",
      ext: ".css"
    },
    js: {
      cmt: "// #{hash_string}",
      ext: ".js",
    },
    swift: {
      cmt: "// #{hash_string}",
      ext: ".swift",
    },
  }
  languages[lang.to_sym]
end

def prepend_hash(folders, options, hash_string)
  begin
    languages = options[:language].map { |l| language_props(l, hash_string) }
    extensions = languages.map { |e| e[:ext] }
    list = "git ls-files #{folders}"
    list += " --full-name | grep -Ev '#{options[:ignore_files].join("|")}'" if options[:ignore_files]
    list += " | grep '#{extensions.join("\\|")}'" if options[:language]
    fs = `#{list}`
    fs = fs.split("\n")
    fs = [options[:file]] if options[:file]
    fs.each do |file|
      lang = languages.find { |f| f[:ext] == File.extname(file) }
      next unless lang && File.readlines(file).first&.delete!("\n") != lang[:cmt]
      `echo "#{lang[:cmt]}\n$(cat #{file})" > #{file}`
    end
    puts "Done!"
  rescue Exception => e
    puts e.message
  end
end
prepend_hash(folder, options, hash_string)
