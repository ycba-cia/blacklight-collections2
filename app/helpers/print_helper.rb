require 'net/http'
require 'json'

module PrintHelper

  def print_images(id,index)
    markup = ""
    #test_image = "https://images.britishart.yale.edu/iiif/1b747e8f-7754-482c-b5a2-9e1dc1986f4b/full/full/0/native.jpg"
    #images = [1]

    #images,pixels = get_images_from_sources(id) #deprecated for cds2
    if index=="9999" #no image,bypass image lookup
      markup = "</br>"
    else
      images, pixels, captions = get_images_from_cds2(id,index)
      #puts "number of images:#{images.size}"
      #puts "size param:#{@size}"
      images.each_with_index do |f, i|
        break if i >= @size.to_i
        markup += "<div style=\"page-break-after: always\">"
        markup += "<img class=\"contain\" src=\"#{f}\" width=\"#{pixels[i][0]}\" height=\"#{pixels[i][1]}\" style=\"object-fit: contain;\">"
        #markup +="</br><div class=\"printlido\" style=\"font-size: 14px;\"><dt style=\"overflow: hidden;\">#{captions[i]}</dt></div></br>" unless captions[0]=="indie"
        markup +="</br><div class=\"printlido col-xs-5\">#{captions[i]}</div></br>" unless captions[0]=="indie"
        markup += "</div>"
        #puts f
      end
      #markup += "</br>"
    end
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
    if index=="9998"
      return get_all_images_from_iiifv3(manifest,index)
    else
      return get_images_from_iiifv3(manifest,index)
    end
  end


  def get_images_from_iiifv3(manifest,index)
    images = Array.new
    pixels = Array.new
    uri = URI(manifest)
    #begin
      json = JSON.load(URI.open(manifest))

    image = json["items"][index.to_i]["items"][0]["items"][0]["body"]["id"]
    image = image.split("/").each_with_index.map { |v,i| i==7 ? ",700" : v }.join("/")
    images.push(image)
    pixels.push(["700","800"])
    #rescue
    #  puts "Error getting print image from manifest: #{manifest}"
    #end
    return images,pixels,["indie"]
  end


  def get_all_images_from_iiifv3(manifest,index)
    images = Array.new
    pixels = Array.new
    captions = Array.new
    uri = URI(manifest)
    #begin
    json = JSON.load(URI.open(manifest))
    index = 0
    while index >= 0
      image = json["items"][index.to_i]["items"][0]["items"][0]["body"]["id"]
      image = image.split("/").each_with_index.map { |v,i| i==7 ? ",700" : v }.join("/")
      caption = json["items"][index.to_i]["label"]["en"][0]
      images.push(image)
      pixels.push(["700","800"])
      captions.push(caption)
      #rescue
      #  puts "Error getting print image from manifest: #{manifest}"
      #end
      index += 1
      index = -1 if json["items"][index.to_i].nil?
    end
    puts "IMAGES:#{images.inspect}"
    return images,pixels,captions
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