require 'net/http'
require 'json'

module PrintHelper

  def print_images(id,index,manifest_path)
    markup = ""
    #test_image = "https://images.britishart.yale.edu/iiif/1b747e8f-7754-482c-b5a2-9e1dc1986f4b/full/full/0/native.jpg"
    #images = [1]

    #images,pixels = get_images_from_sources(id) #deprecated for cds2
    if index=="9999" #no image,bypass image lookup
      markup = "</br>"
    else
      images, pixels, captions = get_images_from_cds2(id,index,manifest_path)
      #puts "number of images:#{images.size}"
      #puts "size param:#{@size}"
      images.each_with_index do |f, i|
        break if i >= @size.to_i
        markup += "<div style=\"page-break-after: always;\">"
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

  def get_images_from_cds2(id,index,manifest_path)
    if id.starts_with?("tms")
      objid = id.gsub("tms:","")
      manifest = "https://manifests.collections.yale.edu/ycba/obj/#{objid}"
    end
    if id.starts_with?("orbis")
      objid = id.gsub("orbis:","")
      manifest = "https://manifests.collections.yale.edu/ycba/orb/#{objid}"
    end
    if id.starts_with?("archival_objects")
      objid = id.gsub("archival_objects:","")
      manifest = "https://manifests.collections.yale.edu/ycba/aas/#{objid}"
    end
    if id.starts_with?("alma")
      #objid = id.gsub("alma:","")
      manifest = "https://manifests.collections.yale.edu/ycba/#{manifest_path}"
    end
    if id.starts_with?("artists")
      objid = id.gsub("artists:","")
      manifest = "https://manifests.collections.yale.edu/ycba/cre/#{objid}"
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
    begin
      json = JSON.load(URI.open(manifest))
    rescue
      if manifest.split("/")[4] = "aas"
        manifest = manifest.sub("/aas/","/ras/")
        json = JSON.load(URI.open(manifest))
      end
    end

    image = json["items"][index.to_i]["items"][0]["items"][0]["body"]["id"]
    height = json["items"][index.to_i]["height"]*2
    unless height < 700
      height = 700
    end
    image = image.split("/").each_with_index.map { |v,i| i==7 ? ",#{height}" : v }.join("/")
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
    begin
      json = JSON.load(URI.open(manifest))
    rescue
      if manifest.split("/")[4] = "aas"
        manifest = manifest.sub("/aas/","/ras/")
        json = JSON.load(URI.open(manifest))
      end
    end
    index = 0
    while index >= 0
      image = json["items"][index.to_i]["items"][0]["items"][0]["body"]["id"]
      height = json["items"][index.to_i]["height"]*2
      unless height < 700
        height = 700
      end
      image = image.split("/").each_with_index.map { |v,i| i==7 ? ",#{height}" : v }.join("/")
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
      #s+= "<dd style=\"display:table-cell; vertical-align: bottom;\">#{@document[field][0]}</dd>"
      s+= "<dd style=\"display: flex; align-items: end;\">#{@document[field][0].gsub("--- ---","")}</dd>"
      return s
    else
      return ""
    end
  end
  def print_holdings(id,document)
    s = "<dt style=\"overflow: hidden;\">Holdings:</dt>"
    if ENV["LSP"] == "alma"
      s+= "<dd>#{get_holdings_print_alma(document)}</dd>"
    else
      s+= "<dd>#{get_holdings_print(id)}</dd>"
    end
    return s
  end

  def get_holdings_print_alma(document)
    html = ""

    coll_map = Hash.new
    coll_map["bacrb"] = "Rare Books and Manuscripts"
    coll_map["bacref"] = "Reference Library"

    colls = Hash.new
    colls_short = Hash.new
    document["holdings_coll_ss"].each do |coll|
      colls_short[coll.split("|")[0].to_s] = coll.split("|")[1]
      colls[coll.split("|")[0].to_s] = coll_map[coll.split("|")[1]]
    end

    cn = Hash.new
    document["call_number_ss"].each do |coll|
      cn[coll.split("|")[0].to_s] = coll.split("|")[1]
    end

    cl = Hash.new
    document["credit_line_ss"].each do |coll|
      cl[coll.split("|")[0].to_s] = coll.split("|")[1]
    end

    document["mfhd_ss"].each do |holding|
        html += "<span>#{colls[holding.to_s]}</span></br>" if colls[holding.to_s]
        html += "<span>#{cn[holding.to_s]}</span></br>" if cn[holding.to_s]
        html += "<span>#{cl[holding.to_s]}</span></br>" if cl[holding.to_s]
        html += "</br>"
    end
    html = html[0...-5]
    return html.html_safe
  end

  def get_holdings_print(id)
    begin
      mfhd = ENV["MFHD_BASE"] + id
      #puts "MFHD:" + mfhd
      doc ||= Nokogiri::HTML(URI.open(mfhd,{:read_timeout => 3}))
      mfhd_ids = doc.xpath('//record_list/holding[starts-with(mfhd_loc_code,"bacrb") or starts-with(mfhd_loc_code,"bacref") or starts-with(mfhd_loc_code,"bacia")]/mfhd_id/text()').to_a

    rescue
      return "<span>Unable to reach service.  Holdings currently not available<span></br>".html_safe
    end

    mfhd_ids = mfhd_ids.map { |n|
      n.to_s.strip.gsub("'","''")
    }
    mfhd_ids = [] if mfhd_ids.nil?
    #puts mfhd_ids.inspect

    collections = doc.xpath('//record_list/holding[starts-with(mfhd_loc_code,"bacrb") or starts-with(mfhd_loc_code,"bacref") or starts-with(mfhd_loc_code,"bacia")]/mfhd_loc_code/text()').to_a
    collections = collections.map { |n|
      n.to_s.strip.gsub("'","''")
    }
    collections = [] if collections.nil?
    #puts collections.inspect

    callnumbers = doc.xpath('//record_list/holding[starts-with(mfhd_loc_code,"bacrb") or starts-with(mfhd_loc_code,"bacref") or starts-with(mfhd_loc_code,"bacia")]/mfhd_callno/text()').to_a
    callnumbers = callnumbers.map { |n|
      n.to_s.strip.gsub("'","''")
    }
    callnumbers = [] if callnumbers.nil?
    #puts callnumbers.inspect

    creditlines = doc.xpath('//record_list/holding[starts-with(mfhd_loc_code,"bacrb") or starts-with(mfhd_loc_code,"bacref") or starts-with(mfhd_loc_code,"bacia")]/mfhd_583_field/text()').to_a
    creditlines = creditlines.map { |n|
      n.to_s.strip.gsub("'","''")
    }
    creditlines = [] if creditlines.nil?
    #puts creditlines.inspect

    collections_title = []
    collections.map { |coll|
        collections_title.push("Rare Books and Manuscripts") if coll.start_with?("bacrb")
        collections_title.push("Reference Library") if coll.start_with?("bacref")
        collections_title.push("Archives") if coll.start_with?("bacia")
    }
    collections_title = [] if collections_title.nil?

    html = ""
    collections.each_with_index { |coll, i|
      html += "<span>#{collections_title[i]}</span></br>"
      html += "<span>#{callnumbers[i]}</span></br>"
      html += "<span>#{creditlines[i]}</span></br>" if creditlines[i]!="NA"
      html += "</br>"
    }

    #html = html[0...-5]
    if html.length==0
      html += "<span>Not Available<span></br>"
    end
    return html.html_safe
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
    s+= "<dd style=\"display: flex; align-items: end;\">#{value}</dd>"
    return s
  end


  def print_newline_fields(label,field)
    if @document[field].nil? == false
      s = "<dt>#{label}</dt>"
      s+= "<dd>"
      @document[field].each_with_index do |line,i|
        if @document[field].length() == (i+1)
          s+= "<span>#{line}</span>"
        else
          s+= "#{line}</p>"
        end
        #s+= "<span>#{line}</span></p>" if i == 0
        #s+= "<p>#{line}</p>" if i > 0
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

  def get_resource_pdf_for_ao(doc)
    url = nil
    pdf = nil
    #puts doc.to_json
    return nil if doc["ancestorIdentifiers_ss"].nil?
    doc["ancestorIdentifiers_ss"].each do |f|
      if f.include? "/resources/"
        match_data = f.match(/\/resources\/(\d+)/)
        if match_data
          res = match_data[1]
          pdf = "https://ead-pdfs.library.yale.edu/#{res}.pdf"
          url = "<a href='#{pdf}' target='_blank'>#{pdf}</a>"
        end
      end
    end
    if url.nil?
      return nil
    else
      #return url.html_safe
      return pdf
    end
  end

  def get_resource_pdf_for_res(doc)
    pdf = "https://ead-pdfs.library.yale.edu/#{doc["id"].split(":")[1]}.pdf"
    url = "<a href='#{pdf}' target='_blank'>#{pdf}</a>"
    #return url.html_safe
    return pdf
  end

  def get_resource_pdf(doc)
    #puts doc["id"]
    if doc["id"].start_with?("resources")
      return get_resource_pdf_for_res(doc)
    elsif doc["id"].start_with?("archival")
      return get_resource_pdf_for_ao(doc)
    else
      return nil
    end
  end
end