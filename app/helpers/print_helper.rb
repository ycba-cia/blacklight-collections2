require 'net/http'
require 'json'

module PrintHelper

  def print_images(id)
    markup = ""
    #test_image = "https://images.britishart.yale.edu/iiif/1b747e8f-7754-482c-b5a2-9e1dc1986f4b/full/full/0/native.jpg"
    #images = [1]

    images = get_images_from_sources(id)
    images.each_with_index do |f, i|
      break if i >= @size.to_i
      markup += "<div style=\"page-break-after: always\">"
      markup += "<img class=\"contain\" src=\"#{f}\" width=\"700\" height=\"800\" style=\"object-fit: contain;\">"
      markup += "</div>"
      #puts f
    end
    #markup += "</br>"
    markup.html_safe
  end

  def get_images_from_iiif(id)
    id = parse_tms_id(id)
    url = "https://manifests.britishart.yale.edu/manifest/#{id}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    j = JSON.parse(response)
    images = Array.new
    if j["sequences"][0].nil? == false && j["sequences"][0]["canvases"][0].nil? == false
      j["sequences"][0]["canvases"].each do |c|
        if c["images"][0].nil? == false && c["images"][0]["resource"].nil? == false
          i1 = c["images"][0]["resource"]["@id"]
          i2 = i1.split("/")
          i2[6] = "700,"
          i3 = i2.join("/")
          images.push(i3)
        end
      end
    end
    #puts images.inspect
    images
  end

  def get_images_from_cds(id)
    if id.starts_with?("tms")
      id = id.gsub("tms:","")
      type = 2
    end
    if id.starts_with?("orbis")
      id = id.gsub("orbis:","")
      type = 1
    end
    url = "https://deliver.odai.yale.edu/info/repository/YCBA/object/#{id}/type/#{type}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    j = JSON.parse(response)
    images = Array.new
    j.each_with_index do |d, i|
      if j["#{i}"]["derivatives"].nil? == false && j["#{i}"]["derivatives"].size > 0
        if j["#{i}"]["derivatives"]["3"].nil? == false
          images.push(j["#{i}"]["derivatives"]["3"]["source"])
          next
        end
        if j["#{i}"]["derivatives"]["2"].nil? == false
          images.push(j["#{i}"]["derivatives"]["2"]["source"])
          next
        end
        if j["#{i}"]["derivatives"]["1"].nil? == false
          images.push(j["#{i}"]["derivatives"]["1"]["source"])
          next
        end
      end
    end
    images
  end

  def parse_tms_id(id)
    id.gsub("tms:","")
  end

  def get_images_from_sources(id)
    if id.starts_with?("tms")
      if manifest_exists?(id)
        return get_images_from_iiif(id)
      else
        # https://deliver.odai.yale.edu/info/repository/YCBA/object/160/type/2
        return get_images_from_cds(id)
      end
    end
    if id.starts_with?("orbis")
      # https://deliver.odai.yale.edu/info/repository/YCBA/object/11676042/type/1
      return get_images_from_cds(id)
    end
  end

  def manifest_exists?(id)
    id = parse_tms_id(id)
    url = "https://manifests.britishart.yale.edu/manifest/#{id}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    begin
      j = JSON.parse(response)
    rescue
      return false
    end
    return true
  end

  def get_solr_doc(id)
    url = "#{request.protocol}#{request.host_with_port}/catalog/#{id}.json"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    j = JSON.parse(response)
    #puts j["response"]["document"]["author_ss"]
    return j["response"]["document"]
  end

  def print_fields(label,field)
    if @document[field].nil? == false
      s = "<dt>#{label}</dt>"
      s+= "<dd>#{@document[field][0]}</dd>"
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