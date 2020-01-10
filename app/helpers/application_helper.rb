require 'net/http'
require 'json'
require 'time'

module ApplicationHelper

  def render_as_link options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

    links = []
    options[:value].each {  |link|
      links.append(link_to "#{link}", "#{link}", target: '_blank')
    }

    links.join('<br/>').html_safe
  end

  def render_aeon_from_call_number options={}
    #method specific to call number
    collection = get_one_value(options[:document][:collection_ss])
    values = []
    if collection=="Paintings and Sculpture" || collection=="Frames" || collection=="Reference Library"
      options[:value].each do |v|
        values.append(v)
      end
    else
      options[:value].each do |v|
        #don't link to aeon if onview per https://github.com/ycba-cia/blacklight-collections2/issues/78
        if get_one_value(options[:document][:onview_ss]) == "On view"
          values.append(v)
        else
          values.append(v + " [" + create_aeon_link(options[:document],v.html_safe) + "]")
        end
      end
    end
    values.join('<br/>').html_safe
  end

  def sort_values_and_link_to_facet options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[#{options[:field]}][]=#{v}\">#{v}</a> | " }.join('</br>').chomp(" | ").html_safe
  end

  def sort_values_and_link_to_topic options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[topic_ss][]=#{v}\">#{v}</a> | " }.join('</br>').chomp(" | ").html_safe
  end

  def sort_values_and_link_to_topic_no_pipes options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[topic_ss][]=#{v}\">#{v}</a>" }.join('</br>').html_safe
  end

  def link_to_author options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    full_author = options[:document][:auth_author_display_ss]
    options[:value].each_with_index.map { |v, i| "<a href=\"/?f[author_ss][]=#{v}\">#{full_author[i]}</a> | " }.join('</br>').chomp(" | ").html_safe
  end

  #used with render_related_content? method in catalog_controller.rb
  def render_related_content options={}
    links = []
    options[:value].each {  |item|
      text, url = item.split("\n")
      if text.length==0
        links.append(link_to "#{url}", url, target: '_blank')
      else
        links.append(link_to "#{text}", url, target: '_blank')
      end
    }
    links.join('<br/>').html_safe
  end

  def render_citation options={}

    i = -1
    sorted = options[:value].sort_by { |d|
      i += 1
      if options[:document][:citation_sort_ss].nil?
        "zzzz"
      elsif options[:document][:citation_sort_ss][i].nil?
        "zzzz"
      elsif options[:document][:citation_sort_ss][i] == "Unknown"
        "zzzz"
      else
        options[:document][:citation_sort_ss][i]
      end
    }
    citations = []
    sorted.each {  |citation|
      citations.append("<p>" + citation + "</p></i>")
    }
    citations.join(' ').html_safe
  end

  def render_exhibitions options={}
    exhs = []
    sorted = options[:value].sort_by { |d|
      extract_date(d)
    }
    sorted.reverse!
    sorted.each {  |exh|
      exhs.append("<p><a href=\"/?f[exhibition_history_ss][]=#{URI::encode(exh)}\">#{exh}</a></p>")
    }
    exhs.join.html_safe
  end

  def extract_date(d)
    if d.match(/(\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?(\d{1,2}\D?)?\D?((19[1-9]\d|20\d{2})|\d{2})/)
      convert_date(d.match(/(\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?(\d{1,2}\D?)?\D?((19[1-9]\d|20\d{2})|\d{2})/)[0])
    else
      Date.parse "9999-12-31"
    end
  end

  def convert_date(str)
    time = Time.parse(str)
    time2 = time.strftime("%Y-%m-%d")
    Date.parse(time2)
  end


  def combine_topic_subject options={}
    subjects = []
    subjects = subjects + options[:document][:topic_subjectConcept_ss] if options[:document][:topic_subjectConcept_ss]
    subjects = subjects + options[:document][:topic_subjectEvent_ss] if options[:document][:topic_subjectEvent_ss]
    subjects = subjects + options[:document][:topic_subjectObject_ss] if options[:document][:topic_subjectObject_ss]
    subjects.join(' ').html_safe
  end

  def combine_curatorial_comments options={}
    str = ""
    options[:value].each_with_index { |v,i|
      if options[:document][:curatorial_comment_auth_ss] && options[:document][:curatorial_comment_auth_ss][i] &&
          options[:document][:curatorial_comment_date_ss] && options[:document][:curatorial_comment_date_ss][i]
        str = str + v + "</br>--" + options[:document][:curatorial_comment_auth_ss][i] + "," + options[:document][:curatorial_comment_date_ss][i] + "</br>"
      else
        str = str + v + "</br>"
      end
    }
    return str.html_safe
  end

  def render_search_per_line options={}
    options[:value].each {  |link|
      links.append(link_to "#{link}", "#{link}")
    }
    links.join('<br/>').html_safe
  end

  def cds_info_url(id, type = 2)
    cds = Rails.application.config_for(:cds)
    "https://#{cds['host']}/info/repository/YCBA/object/#{id}/type/#{type}"
  end

  def cds_thumbnail_url(id, type = 2)
    cds = Rails.application.config_for(:cds)
    "https://#{cds['host']}/content/repository/YCBA/object/#{id}/type/#{type}/format/1"
  end

  def display_rights(document)
    rights_text = document['ort_ss']
    rights_text = rights_text[0] if rights_text

    rights_statement_url = document['rightsURL_ss']
    if rights_statement_url
      rights_text ||= 'Unknown'
      rights_statement_url = rights_statement_url[0]
    end

    if rights_text
        if rights_statement_url
          html = link_to( rights_text, "#{rights_statement_url}", target: "_blank", rel: "nofollow")
        elsif rights_text
          html = rights_text
        end
    end
    html
  end

  def image_request_link(document)
    url = "https://britishart.yale.edu/request-images?"
    url += "id=#{field_value(document,'recordID_ss')}&"
    url += "num=#{field_value(document,'callnumber_txt')}&"
    url += "collection=#{field_value(document,'collection_txt')}&"
    url += "creator=#{field_value(document,'author_ss')}&"
    url += "title=#{field_value(document,'title_txt')}&"
    url += "url=#{field_value(document,'url_txt')}"
    url
  end

  def information_link_subject(document)
    subject = "[Online Collection] #{field_value(document,'callnumber_txt')}, #{field_value(document,'title_txt')}, #{field_value(document,'author_ss')} "
  end

  def information_link_subject_on_view(document)
    subject = "[Onview Request] #{field_value(document,'callnumber_txt')}, #{field_value(document,'title_txt')}, #{field_value(document,'author_ss')} "
  end

  def field_value(document, field)
    value = document[field][0] if document[field]
    value ||= ''
  end

  private

  def thumb(document, options)
    url = doc_thumbnail(document)
    if document['recordtype_ss'] and document['recordtype_ss'][0].to_s == 'marc'
      if document['isbn_ss']
        url = "/bookcover/isbn/#{document['isbn_ss'][0]}/size/medium"
      #elsif document['url_ss'] and document['url_ss'][0].start_with?('https://hdl.handle.net/10079/bibid/')
      #  cds_id = document['url_ss'][0].gsub('https://hdl.handle.net/10079/bibid/', '')
      else
        cds_id = document['id'].split(":")[1]
        cds = Rails.application.config_for(:cds)
        url = "https://#{cds['host']}/content/repository/YCBA/object/#{cds_id}/type/1/format/1"
      end
    end
    url ||= path_to_image('not_available1.png')
    #square = path_to_image('square.png')
    error_img = path_to_image('not_available1.png')
    author = document['auth_author_display_ss'].nil? == false ? document['auth_author_display_ss'][0] : ""
    title_short = document['title_short_ss'].nil? == false ? document['title_short_ss'][0] : ""
    image_tag url, alt: "#{author} #{title_short}", onerror: "this.src='#{error_img}';"
  end

  def doc_thumbnail(document)
    document['thumbnail_ss'][0] if document['thumbnail_ss'] and document['thumbnail_ss'][0]
  end

  def get_export_url_xml(doc)
    if doc['recordtype_ss']
      if doc['recordtype_ss'][0].to_s == 'marc'
        url = "https://libapp.library.yale.edu/OAI_BAC/src/OAIOrbisTool.jsp?verb=GetRecord&identifier=oai:orbis.library.yale.edu:"+get_bib_from_handle(doc)+"&metadataPrefix=marc21"
      elsif doc['recordtype_ss'][0].to_s == 'lido'
        url = "http://collections.britishart.yale.edu/oaicatmuseum/OAIHandler?verb=GetRecord&identifier=oai:tms.ycba.yale.edu:" + doc['recordID_ss'][0] +"&metadataPrefix=lido" if doc['recordID_ss']
      elsif doc['recordtype_ss'][0].to_s == 'mods'
        url = "" #8/8/17 some rare books have this but not supported
      else
        url = ""
      end
    end
    return url
  end

  def get_export_url_rdf(doc)
    if doc['recordtype_ss']
      if doc['recordtype_ss'][0].to_s == 'marc'
        url = "https://collections.britishart.yale.edu/vufind/Record/"+doc['id']+"/Export?style=RDF"
      elsif doc['recordtype_ss'][0].to_s == 'lido'
        url = "https://collection.britishart.yale.edu/id/page/object/"+doc['recordID_ss'][0] if doc['recordID_ss']
      elsif doc['recordtype_ss'][0].to_s == 'mods'
        url == ""  #8/8/17 some rare books have this but not supported
      else
        url = ""
      end
    end
    return url
  end

  def get_bib_from_handle(doc)
    if doc['url_ss'] and doc['url_ss'][0].start_with?('https://hdl.handle.net/10079/bibid/')
      bib = doc['url_ss'][0].gsub('https://hdl.handle.net/10079/bibid/', '')
    elsif doc['url_ss'] and doc['url_ss'][0].start_with?('http://hdl.handle.net/10079/bibid/')
      bib = doc['url_ss'][0].gsub('http://hdl.handle.net/10079/bibid/', '')
    else
      bib = "" #or return no bib to extract from url_ss field
    end
    return bib
  end

  def show_svg(path)
    File.open("app/assets/images/#{path}", "rb") do |file|
      raw file.read
    end
  end

  def concat_caption(doc)
    fields = Array.new
    fields.push doc['author_ss'] if doc['author_ss']
    fields.push doc['title_ss'] if doc['title_ss']
    fields.push doc['publishDate_ss'] if doc['publishDate_ss']
    fields.push doc['format_ss'] if doc['format_ss']
    fields.push doc['credit_line_ss'] if doc['credit_line_ss']
    fields.push doc['callnumber_ss'] if doc['callnumber_ss']
    caption = fields.join(", ")
    return caption
  end

  def get_marc_caption(doc)
    url = "https://deliver.odai.yale.edu/info/repository/YCBA/object/#{doc["id"].split(":")[1]}/type/1"
    json = JSON.load(open(url))
    caption = ""
    if json["0"] && json["0"]["metadata"] && json["0"]["metadata"]["caption"]
      caption = json["0"]["metadata"]["caption"]
    else
      caption = "Caption not found"
    end
    return caption
  end

  def marc_field?(doc)
    doc['recordtype_ss'] and doc['recordtype_ss'][0].to_s == 'marc'
  end

  def copyrighted?(doc)
    if doc['rights_ss'] && (doc['rights_ss'][0].to_s=="under copyright" || doc['rights_ss'][0].to_s=="copyrighted")
      return true
    else
      return false
    end
  end

  def get_aeon_endpoint
    #dev: local_env.yml get parsed into ENV in config/application.rb
    #heroku: no local_env.yml just set the ENV vars directly
    #y = YAML.load_file(Rails.root.join("config","local_env.yml"))
    #return y["AEON_ENDPOINT"]
    #
    ENV["AEON_ENDPOINT"]
  end

  def get_bib_lookup
    #dev: local_env.yml get parsed into ENV in config/application.rb
    #heroku: no local_env.yml just set the ENV vars directly
    #y = YAML.load_file(Rails.root.join("config","local_env.yml"))
    #return y["BIB_LOOKUP"]
    ENV["BIB_LOOKUP"]
  end
  #aeon methods
  def create_aeon_link(doc,call_number)
    #aeon = "https://aeon-mssa.library.yale.edu/aeon.dll?" #production
    #aeon = "https://aeon-test-mssa.library.yale.edu/aeon.dll?" #test
    aeon = get_aeon_endpoint
    #
    #start here,get fields, get mfhd and apply a link underline styling, and try for P&D as well
    action = 10
    form = 20
    value = "GenericRequestMonograph"
    site = "YCBA"
    callnumber = call_number
    title = get_one_value(doc["title_ss"]).gsub("'","%27")
    author = get_one_value(doc["author_ss"]).gsub("'","%27")
    publishdate = get_one_value(doc["publishDateFacet_ss"])
    physical = get_one_value(doc["physical_ss"])
    location = map_collection(doc["collection_ss"])
    url = get_one_value(doc["url_ss"])
    mfhd = get_mfhd(doc["url_ss"])

    #for Prints and Drawings only
    collection = get_one_value(doc["collection_ss"])
    if collection == "Prints and Drawings"
      physical = get_one_value(doc["format_ss"])
      location = get_one_value(doc["location_ss"])
      mfhd = ""
    end

    #puts "callnumber:#{callnumber}"
    #puts "title:#{title}"
    #puts "author:#{author}"
    #puts "publishdate:#{publishdate}"
    #puts "physical:#{physical}"
    #puts "location:#{location}"
    #puts "url:#{url}"
    #puts "mfhd:#{mfhd}"

    aeon += "Action=#{action}&"
    aeon += "Form=#{form}&"
    aeon += "Value=#{value}&"
    aeon += "Site=#{site}&"
    aeon += "CallNumber=#{callnumber}&"
    aeon += "ItemTitle=#{title}&"
    aeon += "ItemAuthor=#{author}&"
    aeon += "ItemDate=#{publishdate}&"
    aeon += "Format=#{physical}&"
    aeon += "Location=#{location}&"
    aeon += "mfhdID=#{mfhd}&"
    aeon += "EADNumber=#{url}"

    onview = location = get_one_value(doc["onview_ss"])
    if onview == "On view"
      #suppress this per https://github.com/ycba-cia/blacklight-collections2/issues/78
      #pdrequest = "mailto:ycba.studyroom@yale.edu?subject=#{information_link_subject_on_view(doc)}"
      #anchor_tag = "<a href='#{pdrequest}'>Request for onview object</a>"
      return ""
    else
      anchor_tag = "<a href='#{aeon}'>Request for use in the YCBA Study Room</a>"
    end
    return anchor_tag.html_safe
  end

  def get_one_value(field)
    defined?(field) && defined?(field[0]) ? field[0] : ""
  end

  def map_collection(field)
    return "bacrb" if get_one_value(field)=="Rare Books and Manuscripts"
    return "bacref" if get_one_value(field)=="Reference Library"
  end

  def get_mfhd(field)
    url = get_one_value(field)
    return "" unless url.start_with?("http://hdl.handle.net/10079/bibid/")
    bibid = url.split("/").last
    #source = "https://libapp-test.library.yale.edu/VoySearch/GetBibItem?bibid="+bibid
    source= get_bib_lookup + bibid
    resp = Net::HTTP.get_response(URI.parse(source))
    data = resp.body
    result = JSON.parse(data)
    mfhd = parse_mfhd(result)
    return mfhd
  end

  def parse_mfhd(r)
    begin
      mfhd = r["record"][0]["items"][0]["mfhdid"]
    rescue
      mfhd = ""
    end
    return mfhd
  end
  #end aeon methods

  def get_frame_link_label(doc)
    c = doc["collection_ss"][0]
    if c == "Frames"
      label = "Link to Framed Image:"
    else
      label = "Link to Frame:"
    end
  end

  def get_frame_link(doc)
    return nil if doc["callnumber_ss"].nil?
    cn = doc["callnumber_ss"][0]
    solr_config = Rails.application.config_for(:blacklight)
    solr = RSolr.connect :url => solr_config["url"]
    if cn.end_with?("FR")
      id = query_solr(solr,"callnumber_ss","#{cn.gsub("FR","")}")
      link = link_to cn.gsub("FR",""), "#{request.protocol}#{request.host_with_port}/catalog/#{id}", method: :get
    else
      id = query_solr(solr,"callnumber_ss","#{cn}FR")
      link = link_to "#{cn}FR", "#{request.protocol}#{request.host_with_port}/catalog/#{id}", method: :get
    end
    link = "" if id.nil?
    link
  end

  def query_solr(solr,field,value)
    response = solr.post "select", :params => {
        :fq=>"#{field}:\"#{value}\""
    }
    return nil if response['response']['docs'].length == 0
    response['response']['docs'][0]["id"]
  end

  def render_ycba_item_header(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    fontsize = options.fetch(:fontsize, "12px")
    document ||= @document

    header = Array.new
    header.push(content_tag(tag, document["auth_author_display_ss"][0], style: "font-size: #{fontsize}")) if document["auth_author_display_ss"]
    header.push(content_tag(tag, document["title_short_ss"][0], style: "font-weight: bold; font-size: #{fontsize}")) if document["title_short_ss"]
    header.push(content_tag(tag, document["publishDate_ss"][0], style: "font-size: #{fontsize}")) if document["publishDate_ss"]

    fullheader = header.join("&nbsp;").html_safe
    content_tag("div", fullheader, style:"text-align:center", itemprop: "name")
  end
end
