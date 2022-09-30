require 'net/http'
require 'json'

module PrintHelper

  def print_images(id,index)
    markup = ""
    #test_image = "https://images.britishart.yale.edu/iiif/1b747e8f-7754-482c-b5a2-9e1dc1986f4b/full/full/0/native.jpg"
    #images = [1]

    #images,pixels = get_images_from_sources(id) #deprecated for cds2
    images, pixels = get_images_from_cds2(id,index)
    images.each_with_index do |f, i|
      break if i >= @size.to_i
      markup += "<div style=\"page-break-after: always\">"
      markup += "<img class=\"contain\" src=\"#{f}\" width=\"#{pixels[i][0]}\" height=\"#{pixels[i][1]}\" style=\"object-fit: contain;\">"
      markup += "</div>"
      #puts f
    end
    #markup += "</br>"
    markup.html_safe
  end

  def get_images_from_cds2(id,index)
    if id.starts_with?("tms")
      objid = id.gsub("tms:","")
      manifest = "https://manifests.collections.yale.edu/ycba/obj/#{objid}"
    end
    if id.starts_with?("orbis")
      objid = id.gsub("orbis:","")
      manifest = "https://manifests.collections.yale.edu/ycba/orb/#{objid}"
    end
    get_images_from_iiifv3(manifest,index)
  end


  def get_images_from_iiifv3(manifest,index)
    images = Array.new
    pixels = Array.new
    uri = URI(manifest)
    #begin
      json = JSON.load(URI.open(manifest))

    image = json["items"][index.to_i]["items"][0]["items"][0]["body"]["id"]
    images.push(image)
    pixels.push(["700","800"])
    #rescue
    #  puts "Error getting print image from manifest: #{manifest}"
    #end
    return images,pixels
  end

  def get_solr_doc(id,protocol,hostwport)
    #url = "#{request.protocol}#{request.host_with_port}/catalog/#{id}.json"
    url = "#{protocol}#{hostwport}/catalog/#{id}.json"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    j = JSON.parse(response)
    #puts j["response"]["document"]["author_ss"]
    return j["response"]["document"]
  end

  def print_fields(label,field)
    if @document[field].nil? == false
      s = "<dt style=\"overflow: hidden;\">#{label}</dt>"
      s+= "<dd>#{@document[field][0]}</dd>"
      return s
    else
      return ""
    end
  end

  def print_string(label,field)
    if field.nil? == false
      s = "<dt style=\"overflow: hidden;\">#{label}</dt>"
      s+= "<dd>#{field}</dd>"
      return s
    else
      return ""
    end
  end

  def print_fields_default_empty(label,field,default)
    if @document[field].nil?
      value = default
    else
      value = @document[field][0]
    end
    s = "<dt>#{label}</dt>"
    s+= "<dd>#{value}</dd>"
    return s
  end


  def print_newline_fields(label,field)
    if @document[field].nil? == false
      s = "<dt>#{label}</dt>"
      s+= "<dd>"
      @document[field].each_with_index do |line,i|
        s+= "<span>#{line}</span></p>" if i == 0
        s+= "<p>#{line}</p>" if i > 0
      end
      s+= "</dd>"
      return s
    else
      return ""
    end
  end

  def print_sep_fields(label,field)
    if @document[field].nil? == false
      s = "<dt>#{label}</dt>"
      s+= "<dd>"
      @document[field].each_with_index do |line,i|
        s+= "#{line} | "
      end
      s.chomp!(" | ")
      s+= "</dd>"
      return s
    else
      return ""
    end
  end
end