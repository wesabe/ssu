namespace :export do
  # Export words/list.js from either a dictionary file or from the
  # word list found at wordcount.org. The default is the latter, and
  # 10,000 words:
  #
  #   $ rake export:words
  #   Reading words from wordcount.org...
  #   Writing 10000 words to util/words/list.js...
  #
  # This would use the Mac OS X dictionary:
  #
  #   $ rake export:words FILE=/usr/share/dict/words
  #   Reading words from /usr/share/dict/words...
  #   Writing 234936 words to util/words/list.js...
  #
  # It's a good idea to keep the word count low, say 10,000
  # or so, otherwise XulRunner gets cranky:
  #
  #   $ rake export:words FILE=/usr/share/dict/words WC=10000
  #   Reading words from /usr/share/dict/words...
  #   Writing 10000 words to util/words/list.js...
  desc "Create words/list.js"
  task :words do
    path = ENV['FILE']
    count = ENV['WC']
    count = (count || 10_000).to_i
    words = []
    if path
      path = File.expand_path(path)
      unless File.exist?(path)
        $stderr.puts "No #{path} available!"
        exit(1)
      else
        puts "Reading words from #{path}..."
        word = nil
        File.open(path) {|f| words << word.chomp while (word = f.gets) and (count -= 1) >= 0 }
      end
      count = words.size
    else
      puts "Reading words from wordcount.org..."
      require 'open-uri'
      until words.size >= count
        puts "`- reading from word #{words.size}"
        open("http://wordcount.org/dbquery.php?toFind=#{words.size}&method=SEARCH%5FBY%5FINDEX").read.
          split("&").
          each {|p| words << $1 if p =~ /^word\d+=(.*)$/}
      end
    end
    words = words.first(count).sort

    puts "Writing #{words.size} words to util/words/list.js..."
    File.open("application/chrome/content/wesabe/util/words/list.js", "w") do |list|
      list.puts 'module.exports = {'

      words.each do |word|
        list.puts %{  "#{word.downcase}": true,}
      end

      list.puts '};'
    end
  end
end
