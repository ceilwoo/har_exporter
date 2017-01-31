require 'cgi'
require 'json'
require 'base64'
require 'uri'
require 'fileutils'

@type = ["text","application/ogg", "image", "application/octet-stream"]

file_path = ARGV[0]
if !file_path || !File.exist?(file_path)
    puts "[error] - ARGV[0] - file_path error or file not exist"
    exit
end
@file_base_path = File.dirname(file_path)

har = JSON.parse(IO.read(file_path))

def check_file_type file_type# {{{
    result = false
    @type.each {|t|
        if file_type.include?(t)
            result = true
        end
    }
    return result
end# }}}

i = 1
har["log"]["entries"].each {|h|
    #text/html application/ogg image/png image/jpeg 
    mime_type =  h["response"]["content"]["mimeType"]
    next if !check_file_type(mime_type)
    url = h["request"]["url"]
    #puts url 
    content = h["response"]["content"]["text"]
    content_encoding = h["response"]["content"]["encoding"]

    uri = URI.parse(url)
    dirname  = uri.host + File.dirname(uri.path)
    filename = File.basename(uri.path)
    extname  = File.extname(uri.path)
    filepath = dirname + "/" + filename

    fulldir      = @file_base_path + "/" + dirname
    fullfilepath = fulldir + "/" + filename

    #puts "[dir]#{dirname}, [file]#{filename}, [ext]#{extname}"
    if extname == "" && mime_type == "text/html"
        fulldir += "/" + filename
        fullfilepath += "/index.html"
    end

    unless File.directory?(fulldir)
      FileUtils.mkdir_p(fulldir)
    end

    raw_data = if content_encoding == "base64"
        Base64.decode64(content)
    else
        content
    end

    if !File.exist?(fullfilepath)
        puts "* (#{mime_type}) " + filepath
        IO.write(fullfilepath, raw_data)
    else
        puts "- " + filepath
    end
    i += 1
}
puts "-------- total: #{i} files -------"
puts "[base_path] #{@file_base_path}"
