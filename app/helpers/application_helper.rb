require 'net/http'
require 'json'
require 'time'
require 'uri'
require 'cgi'

module ApplicationHelper

  #deprecated
=begin
  def rights_helper options={}
    #these no longer apply as using "Under Certain Circumstances" and "Free to Use"
    popup = ""
    popup = "Copyright yet to be determined" if options == "unknown"
    popup = "Works that have no known copyright" if options == "public domain"
    popup = "Works that are in copyright" if options == "under copyright"
    popup = "Works that are not in copyright, but works or their images have other restrictions" if options == "rights reserved"
    options = "Unknown" if options == "unknown"
    options = "Public Domain" if options == "public domain"
    options = "Under Copyright" if options == "under copyright"
    options = "Rights Reserved" if options == "rights reserved"
    options = "<span title=\"#{popup}\">#{options}</span>"
    options.html_safe
  end
=end

  def capitalize options={}
    options.upcase_first
  end

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

  #deprecated
  def handle_qualifiers options={}
    links = []
    options[:value].each_with_index { |v, i |
      links.append("<a href=\"/?f[author_removed_ss][]=#{options[:document][:author_removed_ss][i].gsub(';','%3B').gsub('&','%26')}\">#{v}</a>")
    }

    links.join('<br/>').html_safe
  end

  def handle_qualifiers2 options={}
    links = []
    options[:value].each_with_index { |v, i |
      aq = options[:document][:attrib_qual_ss].nil? ? "--" : options[:document][:attrib_qual_ss][i]
      aq = "" if aq=="--"
      suf = options[:document][:author_suffix_ss].nil? ? "--" : options[:document][:author_suffix_ss][i]
      suf = "" if suf=="--"
      links.append("#{aq} <a href=\"/?f[loc_naf_author_ss][]=#{options[:document][:loc_naf_author_ss][i].gsub(';','%3B').gsub('&','%26')}\">#{options[:document][:display_author_ss][i]}</a> #{suf}".strip)
    }
    links.join('<br/>').html_safe
  end

  #deprecated
=begin
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
          values.append(v + " [" + create_aeon_link(options[:document]) + "]")
        end
      end
    end
    values.join('<br/>').html_safe
  end
=end
  def render_aeon_from_access options={}
    #notice during covid
    pd_rb_ia = "<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"
    ref = "<br/><i>Note: Please contact the Reference Library to schedule an appointment [Email #{bacref_email}]</i>"
    ps = "<br><i>Note: To make an appointment to see this work, please contact the Paintings and Sculpture department at #{bacps_email}. Please visit the <a href=\"https://britishart.yale.edu/paintings-and-sculpture\">Paintings and Sculpture collections page</a> on our website for more details.</i>"
    #method specific to call number
    detailed_onview_ss = get_one_value(options[:document][:detailed_onview_ss])
    #puts "D:#{detailed_onview_ss}"
    values = []
    options[:value].each do |v|
      if detailed_onview_ss == "Accessible by appointment in the Study Room"
        values.append("<b>" + v + " [" + create_aeon_link(options[:document]) + "]</b>" + pd_rb_ia)
      elsif detailed_onview_ss == "Accessible by appointment in the Reference Library"
        values.append("<b>" + v + " [" + hours + "]</b>" + ref)
      else
        #values.append("<b>"+v+"</b>" + ps) #revert to this after with new language
        values.append("<b>"+v+"</b>")
      end
    end
    values.join('<br/>').html_safe
  end

  def render_aeon_from_access_callnumber(document,collection,callnumber,mfhd_id)
    #notice during covid
    pd_rb_ia = "<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"
    ref = "<br/><i>Note: Please contact the Reference Library to schedule an appointment [Email #{bacref_email}]</i>"

    value = ""
    if collection.start_with?("bacrb")
      if document["onview_ss"] and document["onview_ss"][0] == "On view at the Yale University Art Gallery"
        value = "<b>On view at the Yale University Art Gallery</b>"
      else
        # value = "<b>View by request in the Study Room [" + create_aeon_link_callnumber(document,callnumber,mfhd_id) + "]</b>" + pd_rb_ia
        value = "<b>[" + create_aeon_link_callnumber(document,callnumber,mfhd_id) + "]</b>"
      end
    elsif collection.start_with?("bacref")
      value = "<b>Accessible in the Reference Library [" + hours + "]</b>" + ref
    elsif collection.start_with?("bacia")
      #value = "<b>Accessible by appointment in the Study Room [" + bacia_email + "]</b>" + pd_rb_ia
      value = "<b>[" + bacia_email + "]</b>"
    end
    value.html_safe
  end

  def hours
    link_to "Hours", "https://britishart.yale.edu/about-us/departments/reference-library-and-archives", target: '_blank'
  end

  def bacia_email
    mail_to "ycba.institutionalarchives@yale.edu", "Email"
  end

  def bacref_email
    mail_to "ycba.reference@yale.edu", "ycba.reference@yale.edu"
  end

  def bacps_email
    mail_to "ycba.paintings@yale.edu", "ycba.paintings@yale.edu"
  end

  def sort_values_and_link_to_facet options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[#{options[:field]}][]=#{v.gsub(';','%3B').gsub('&','%26')}\">#{v}</a> | " }.join('').chomp(" | ").html_safe
  end

  def sort_values_and_link_to_facet_frames options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    collection = options[:document][:collection_ss][0]
    if collection == "Frames"
      sort_frames_subjects(options)
    else
      options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[#{options[:field]}][]=#{v.gsub(';','%3B').gsub('&','%26')}\">#{v}</a> | " }.join('').chomp(" | ").html_safe
    end
  end

  def sort_frames_subjects options={}
    order = Array.new
    options[:value].each do |v|
      order[0] = v if v.start_with?("frame style")
      order[1] = v if v.start_with?("frame status")
      order[2] = v if v.start_with?("frame quality")
      order[3] = v if v.start_with?("frame ornament")
      order[4] = v if v.start_with?("frame feature")
      order[5] = v if v.start_with?("frame cross-section")
      order[6] = v if v.start_with?("frame alteration")
    end
    order.compact.map { |v| "<a href=\"/?f[#{options[:field]}][]=#{v.gsub(';','%3B').gsub('&','%26')}\">#{v}</a> | " }.join('').chomp(" | ").html_safe
  end

  def sort_values_and_link_to_topic options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[topic_ss][]=#{v.gsub(';','%3B').gsub('&','%26')}\">#{v}</a> | " }.join('</br>').chomp(" | ").html_safe
  end

  def sort_values_and_link_to_topic_no_pipes options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
    #facet = "topic_facet"
    options[:value].sort_by(&:downcase).map { |v| "<a href=\"/?f[topic_ss][]=#{v.gsub(';','%3B').gsub('&','%26')}\">#{v}</a>" }.join('</br>').html_safe
  end

  def link_to_author options={}
    #http://localhost:3000/?f[topic_facet][]=woman #example
   options[:value].each_with_index.map { |v, i| "<a href=\"/?f[#{options[:field].gsub('_acc','_ss')}][]=#{v.gsub(';','%3B').gsub('&','%26')}\">#{options[:value][i]}</a> | " }.join('</br>').chomp(" | ").html_safe
  end

  #used with render_related_content? method in catalog_controller.rb
  def render_related_content options={}
    links = []
    options[:value].each {  |item|
      text, url = item.split("\n")
      if text.length==0
        links.append(link_to "#{url}", url, target: '_blank')
      else
        if url.nil?
          links.append(text)
        else
          links.append(link_to "#{text}", url, target: '_blank')
        end
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

  def render_tms_citation_presorted options={}
    presorted_citation = options[:value]
    presorted_citation_links = options[:document][:citationURL_ss]
    combined_with_links = presorted_citation.each_with_index.map { |v,i|
      if presorted_citation_links.nil? || presorted_citation_links[i].nil? || presorted_citation_links[i] == "-"
        "<p>#{v}</i><p>"
      else
        "<p><a target=\"_blank\" href=\"#{presorted_citation_links[i]}\">#{v}</i></a></p>"
      end
    }
    combined_with_links.join(' ').html_safe
  end

  def render_marc_citation_presorted_tab(doc)
    presorted_citation = doc["citation_ss"]
    presorted_citation_links = doc["citationURL_ss"]
    combined_with_links = presorted_citation.each_with_index.map { |v,i|
      if presorted_citation_links.nil? || presorted_citation_links[i].nil? || presorted_citation_links[i] == "-"
        "<p>#{v}</i><p>"
      else
        "<p><a target=\"_blank\" href=\"#{presorted_citation_links[i]}\">#{v}</i></a></p>"
      end
    }
    combined_with_links.join(' ').html_safe
  end

  def render_lido_citation_presorted_tab(doc)
    presorted_citation = doc["linked_citation_ss"]
    presorted_citation_links = doc["citationURL_ss"]
    combined_with_links = presorted_citation.each_with_index.map { |v,i|
      v2 = v.split("|")
      citation = ""
      ils = ""
      oclc = ""
      callnum = ""
      v2.each_with_index { |part,ii|
        if ii == 0
          citation = part
        else
          if part.starts_with?("a")
            ils = part[1..-1]
          elsif part.starts_with?("b")
            oclc = part[1..-1]
          elsif part.starts_with?("c")
            callnum = part[1..-1]
          end
        end
      }
      if presorted_citation_links.nil? || presorted_citation_links[i].nil? || presorted_citation_links[i] == "-"
        if callnum.include?("(YCBA)") && ils.length > 0
          "<p>#{citation}</i> [<a target=\"_blank\" href=\"https://collections.britishart.yale.edu/catalog/orbis:#{ils}\">YCBA</a>]</p>"
        elsif ils.length > 0
          "<p>#{citation}</i> [<a target=\"_blank\" href=\"https://hdl.handle.net/10079/bibid/#{ils}\">ORBIS</a>]</p>"
        elsif oclc.length > 0
          "<p>#{citation}</i> [<a target=\"_blank\" href=\"http://www.worldcat.org/oclc/#{oclc}\">OCLC</a>]</p>"
        else
          "<p>#{citation}</i></p>"
        end
      else
        "<p>#{v2[0]}</i> [<a target=\"_blank\" href=\"#{presorted_citation_links[i]}\">Website</a>]</p>"
      end
    }
    combined_with_links.join(' ').html_safe
  end


  #deprecated 2/4/2021, using render_tms_citation_presorted instead
=begin
  def render_tms_citation options={}

    i = -1
    sorted = options[:value].sort_by { |d|
      i += 1
      if options[:document][:citation_sort_ss].nil? || options[:document][:citation_sort_ss][i].nil? || options[:document][:citation_sort_ss][i] == "Unknown"
        "zzzz"
      else
        options[:document][:citation_sort_ss][i]
      end
    }

    i = -1
    if options[:document][:citationURL_ss]
      sorted_links = options[:document][:citationURL_ss].sort_by  { |d|
        i += 1
        if options[:document][:citation_sort_ss].nil? || options[:document][:citation_sort_ss][i].nil? || options[:document][:citation_sort_ss][i] == "Unknown"
          "zzzz"
        else
          options[:document][:citation_sort_ss][i]
        end
      }
    end

    sorted_with_links = sorted.each_with_index.map {  |v,i|
      if sorted_links.nil? || sorted_links[i].nil? || sorted_links[i] == "-"
        "<p>#{v}</i><p>"
      else
        "<p><a target=\"_blank\" href=\"#{sorted_links[i]}\">#{v}</i></a></p>"
      end
    }
    sorted_with_links.join(' ').html_safe
  end
=end

  def render_exhibitions options={}
    exhs = []
    sorted = options[:value].sort_by { |d|
      extract_date(d)
    }
    sorted.reverse!
    sorted.each {  |exh|
      param = URI.encode_www_form_component(exh)
      exhs.append("<p><a href=\"/?f[exhibition_history_ss][]=#{param.gsub(';','%3B').gsub('&','%26')}\">#{exh}</a></p>")
    }
    exhs.join.html_safe
  end

  def render_exhibitions_tab(doc)
    exhs = []
    sorted = doc["exhibition_history_ss"].sort_by { |d|
      #puts d
      extract_date2(d)
      #extract_date2(d[d.index("(")..-1]) # use limit: nil instead
    }
    sorted.reverse!

    if doc["exhibitionURL_ss"]
      sorted2 = doc["exhibitionURL_ss"].sort_by.with_index { |e,i|
        extract_date2(doc["exhibition_history_ss"][i])
      }
      sorted2.reverse!
    end
    sorted.each_with_index {  |exh, i|
      param = URI.encode_www_form_component(exh)

      if sorted2 && sorted2[i] != '-'
          website = sorted2[i]
      end
      #exhs.append("<p><a href=\"/?f[exhibition_history_ss][]=#{param}\">#{exh}</a></p>")
      exhs.append("<p>#{exh} <span style=\"white-space:nowrap\">[<a href=\"/?f[exhibition_history_ss][]=#{param.gsub(';','%3B').gsub('&','%26')}\" target='_blank'>YCBA Objects in the Exhibition</a>]</span>")
      exhs.append(" <span style=\"white-space:nowrap\">[<a href=\"#{website}\" target='_blank'>Exhibition Description</a>]</span>") if website
      exhs.append("</p>")
    }
    exhs.join.html_safe
  end

  def render_parent options={}
    facet_link = options[:value].map { |item|
      "<p><a href=\"/?f[title_collective_ss][]=#{item.gsub(';','%3B').gsub('&','%26')}\" target='_blank'>Collective Title: #{item}</a></p>"
    }
    facet_link.join.html_safe
  end

  def render_titles_all options={}
    titles = []

    options[:value].each_with_index { |title, i|
      if options[:value].length() == (i + 1)
        titles.append(title)
      else
        titles.append("<p>"+title+"</p>")
      end
    }
    titles.join.html_safe
  end

  def extract_date(d)
    if d.match(/(\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?(\d{1,2}\D?)?\D?((19[1-9]\d|20\d{2})|\d{2})/)
      convert_date(d.match(/(\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?(\d{1,2}\D?)?\D?((19[1-9]\d|20\d{2})|\d{2})/)[0])
    else
      Date.parse "9999-12-31"
    end
  end

  def extract_date2(d)
    if d.match(/(\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?(\d{1,2}\D?)?\D?((19[1-9]\d|20\d{2})|\d{2})/)
      convert_date(d.match(/(\b\d{1,2}\D{0,3})?\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|(Nov|Dec)(?:ember)?)\D?(\d{1,2}\D?)?\D?((19[1-9]\d|20\d{2})|\d{2})/)[0])
    elsif d.match(/\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])/)
      Date.parse(d,limit: nil)
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
    str.gsub!('\n','</br>');
    return str.html_safe
  end

  def combine_curatorial_comments_tab(doc)
    array = Array.new
    doc["curatorial_comment_ss"].each_with_index { |v,i|
      v.gsub!('\n','</br>')
      if doc["curatorial_comment_auth_ss"] && doc["curatorial_comment_auth_ss"][i] &&
          doc["curatorial_comment_date_ss"] && doc["curatorial_comment_date_ss"][i]
        array.append(v + "</br>--" + doc["curatorial_comment_auth_ss"][i] + "," + doc["curatorial_comment_date_ss"][i] + "</br>")
      elsif doc["curatorial_comment_auth_ss"] && doc["curatorial_comment_auth_ss"][i]
          array.append(v + "</br>--" + doc["curatorial_comment_auth_ss"][i] + "</br>")
      else
        array.append(v + "</br>")
      end
    }

    return array
  end

  #deprecated, not in tombstone but in tabs
=begin
  def format_contents options={}
    s = "<ul style='list-style: disc;'>"
    options[:value].each do |s1|
      a = s1.split(" -- ")
      a.each do |s2|
        s = s + "<li>" + s2 + "</li>"
      end
    end
    s = s + "</ul>"
    s.html_safe
  end
=end
  def format_contents_tab(doc)
    s = "<ul style='list-style: disc; margin-left: 15px;'>"
    doc["marc_contents_ss"].each do |s1|
      a = s1.split(" -- ")
      a.each do |s2|
        s = s + "<li>" + s2 + "</li>"
      end
    end
    s = s + "</ul>"
    s.html_safe
  end

  def render_search_per_line options={}
    links = Array.new
    options[:value].each {  |link|
      links.append(link_to "#{link}", "#{link}")
    }
    links.join('<br/>').html_safe
  end

  def render_copyright_status options={}
    label = "Copyright Not Evaluated"
    label = options[:document][:ort_ss][0] if options[:document][:ort_ss]
    #puts "LABEL:#{label}"
    link = "http://rightsstatements.org/vocab/CNE/1.0/"
    link = options[:document][:rightsURL_ss][0] if options[:document][:rightsURL_ss]
    link_to(label, link, target: "_blank", rel: "nofollow")
  end

  def add_alt_publisher options={}
    concat = options[:value]
    if options[:document][:altrep_publisher_ss]
      options[:document][:altrep_publisher_ss].each { |v|
        concat.append(v)
      }
    end
    concat.uniq.join('<br/>').html_safe
  end

  def add_alt_title options={}
    concat = options[:value]
    if options[:document][:altrep_title_ss]
      options[:document][:altrep_title_ss].each { |v|
        concat.append(v)
      }
    end
    concat.uniq.join('<br/>').html_safe
  end

  def add_alt_title_alt options={}
    concat = options[:value]
    if options[:document][:altrep_title_alt_ss]
      options[:document][:altrep_title_alt_ss].each { |v|
        concat.append(v)
      }
    end
    concat.uniq.join('<br/>').html_safe
  end

  def add_alt_edition options={}
    concat = options[:value]
    if options[:document][:altrep_edition_ss]
      options[:document][:altrep_edition_ss].each { |v|
        concat.append(v)
      }
    end
    concat.uniq.join('<br/>').html_safe
  end

  def add_alt_description options={}
    concat = options[:value]
    if options[:document][:altrep_description_ss]
      options[:document][:altrep_description_ss].each { |v|
        concat.append(v)
      }
    end
    concat.uniq.join('<br/>').html_safe
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
    html = ""
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
    if field_value(document,:collection_txt) == "Rare Books and Manuscripts"
      url = "https://britishart.yale.edu/request-images-rare-books-and-manuscripts?"

      begin
        doc = get_mfhd_doc(document)
        callnumbers = doc.xpath('//record_list/holding[starts-with(mfhd_loc_code,"bacrb")]/mfhd_callno/text()').to_a
      rescue
        return "<span>Unable to reach service.  Holdings currently not available<span></br>".html_safe
      end
      callnumbers = callnumbers.map { |n|
        n.to_s.strip.gsub("'","''")
      }
      callnumber = ""
      callnumber = callnumbers[0] if callnumbers.length == 1
      id = document[:id].split(":")[1]

      url += "id=#{id}&"
      url += "num=#{callnumber}&"
      url += "collection=#{field_value(document,:collection_txt)}&"
      url += "creator=#{field_value(document,:author_ss)}&"
      url += "title=#{field_value(document,:title_txt)[0,248]}&"
      url += "url=#{field_value(document,:url_txt)}"
    else
      url = "https://britishart.yale.edu/request-images?"
      url += "id=#{field_value(document,:recordID_ss)}&"
      url += "num=#{field_value(document,:callnumber_txt)}&"
      url += "collection=#{field_value(document,:collection_txt)}&"
      url += "creator=#{field_value(document,:author_ss)}&"
      url += "title=#{field_value(document,:title_txt)[0,248]}&"
      url += "url=#{field_value(document,:url_txt)}"
    end
    url
  end

  def information_link_subject(document)
    subject = "[Online Collection] #{field_value(document,:callnumber_txt)}, #{field_value(document,:title_txt)}, #{field_value(document,:author_ss)} "
  end

  def information_link_subject_on_view(document)
    subject = "[Onview Request] #{field_value(document,:callnumber_txt)}, #{field_value(document,:title_txt)}, #{field_value(document,:author_ss)} "
  end

  def field_value(document, field)
    value = document[field][0] if document[field]
    value ||= ''
  end

  def get_mfhd_base
    #dev: local_env.yml get parsed into ENV in config/application.rb
    #heroku: no local_env.yml just set the ENV vars directly
    #y = YAML.load_file(Rails.root.join("config","local_env.yml"))
    #return y["AEON_ENDPOINT"]
    #
    ENV["MFHD_BASE"]
  end

  def pull_mfhd_doc(document)
    mfhd = get_mfhd_base + document[:id].split(":")[1]
    @doc ||= Nokogiri::HTML(URI.open(mfhd,{:read_timeout => 3}))
  end

  def get_mfhd_doc(document)
    begin
      pull_mfhd_doc(document)
    rescue
      raise "Unable to reach mfhd service"
    end
  end

  def get_holdings(document)
    begin
      doc = get_mfhd_doc(document)
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

    access = collections.each_with_index.map { |coll,i|
      render_aeon_from_access_callnumber(document,coll,callnumbers[i],mfhd_ids[i])
    }
    access = [] if access.nil?
    #puts access.inspect

    collections_title = []
    collections.map { |coll|
        collections_title.push("Rare Books and Manuscripts") if coll.start_with?("bacrb")
        collections_title.push("Reference Library") if coll.start_with?("bacref")
        collections_title.push("Archives") if coll.start_with?("bacia")
    }
    collections_title = [] if collections_title.nil?
    #puts collections_title

    html = ""

    collections.each_with_index { |coll, i|
    html += "<span>#{collections_title[i]}</span></br>"
    html += "<span>#{callnumbers[i]}</span></br>"
    html += "<span>#{creditlines[i]}</span></br>" if creditlines[i]!="NA"
    html += "<span>#{access[i]}</span></br>"
    html+= "</br>"
    }
    html = html[0...-5]
    if html.length==0
      html += "<span>#{document[:collection_ss][0]}</span></br>"
      html += "<span>Not Available<span></br>"
    end
    return html.html_safe
  end

  #private #removed private for rspec scope 9/2/2022

  def thumb(document, options)
    url = doc_thumbnail(document)
    #url = doc_thumbnail_from_manifest(document) #get thumbnails from manifest on the fly
    if document[:recordtype_ss] and document[:recordtype_ss][0].to_s == 'marc'
      if document[:isbn_ss]
        unless document[:collection_ss][0] == "Rare Books and Manuscripts"
          url = "/bookcover/isbn/#{document[:isbn_ss][0]}/size/medium"
        end
      end
    end
    #puts "URL:#{url}"
    url ||= path_to_image('not_available1.png')
    #square = path_to_image('square.png')
    error_img = path_to_image('not_available1.png')
    author = document[:auth_author_display_ss].nil? == false ? document[:auth_author_display_ss][0] : ""
    title_short = document[:title_short_ss].nil? == false ? document[:title_short_ss][0] : ""
    image_tag url, alt: "#{author} #{title_short}", onerror: "this.src='#{error_img}';"
  end

  #deprecated as of cds2
=begin
  def doc_thumbnail(document)
    if document['thumbnail_ss'] and document['thumbnail_ss'][0]
      url = document['thumbnail_ss'][0]
      url.gsub!("http","https") if url.start_with?("http:")
    else
      return nil
    end
    url
  end
=end
  # cds2 replacement
  def doc_thumbnail(d)
    if d[:manifest_thumbnail_ss].nil?
      return nil
    else
      return d[:manifest_thumbnail_ss][0]
    end
  end
  #use doc_thumnail method instead of below method to avoid many http connections rendering results page
=begin
  def doc_thumbnail_from_manifest(d)
    thumbnail = ""
    manifest = "https://manifests.collections.yale.edu/ycba/obj/" + d['id'].split(":")[1] if d['recordtype_ss'][0] == "lido"
    manifest = "https://manifests.collections.yale.edu/ycba/orb/" + d['id'].split(":")[1] if d['recordtype_ss'][0] == "marc"
    #puts "MANIFEST:"+manifest;
    download_array = Array.new()
    begin
      json = JSON.load(open(manifest))
    rescue
      return thumbnail
    end

    begin
      thumbnail = json["items"][0]["thumbnail"][0]["id"]
    rescue
      thumbnail = ""
    end
    return thumbnail
  end
=end

  def get_export_url_xml(doc)
    if doc[:recordtype_ss]
      if doc[:recordtype_ss][0].to_s == 'marc'
        url = "https://libapp.library.yale.edu/OAI_BAC/src/OAIOrbisTool.jsp?verb=GetRecord&identifier=oai:orbis.library.yale.edu:"+get_bib_from_handle(doc)+"&metadataPrefix=marc21"
      elsif doc[:recordtype_ss][0].to_s == 'lido'
        url = "http://harvester-bl.britishart.yale.edu/oaicatmuseum/OAIHandler?verb=GetRecord&identifier=oai:tms.ycba.yale.edu:" + doc[:recordID_ss][0] +"&metadataPrefix=lido" if doc[:recordID_ss]
      end
    end
    return url
  end

  def get_manifest_from_document(doc)
    if doc[:recordtype_ss]
      if doc[:recordtype_ss][0].to_s == 'marc'
        url = "https://manifests.collections.yale.edu/ycba/orb/" + doc[:id].split(":")[1]
      elsif doc[:recordtype_ss][0].to_s == 'lido'
        url = "https://manifests.collections.yale.edu/ycba/obj/" + doc[:id].split(":")[1]
      end
    end
    return url
  end

  #deprecated
=begin
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
=end

  def get_bib_from_handle(doc)
    if doc[:url_ss] and doc[:url_ss][0].start_with?('https://hdl.handle.net/10079/bibid/')
      bib = doc[:url_ss][0].gsub('https://hdl.handle.net/10079/bibid/', '')
    elsif doc[:url_ss] and doc[:url_ss][0].start_with?('http://hdl.handle.net/10079/bibid/')
      bib = doc[:url_ss][0].gsub('http://hdl.handle.net/10079/bibid/', '')
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

  def prepare_concat_field_with_trailing_period(f)
    if f.kind_of?(Array) and f != [""]
      f = f[0]
      if f[-1] != "."
        f += "."
      end
      return f
    else
      return ""
    end
  end

  def prepare_concat_title_short(f)
    if f.kind_of?(Array) and f != [""]
      f = f[0]
      if f[-1] == ":" or f[-1] == "/" or f[-1] == "."
        f = f[0...-1] + "."
      elsif f[-2,2] == ": " or f[-2,2] == "/ " or f[-2,2] == ". "
        f = f[0...-2] + "."
      else
        f += "."
      end
      return f
    else
      return ""
    end
  end

  def concat_caption_marc(doc)
    fields = Array.new
    fields.push prepare_concat_field_with_trailing_period(doc['author_ss'])
    fields.push prepare_concat_title_short(doc['titles_primary_ss'])
    fields.push prepare_concat_field_with_trailing_period(doc['edition_ss'])
    fields.push prepare_concat_field_with_trailing_period(doc['publisher_ss'])
    fields.push prepare_concat_field_with_trailing_period(doc['credit_line_ss'])
    caption = fields.join(" ")
    return caption
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

  #deprecated
=begin
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
=end
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
  #For P&D when not "on view"
  def create_aeon_link(doc)
    #aeon = "https://aeon-mssa.library.yale.edu/aeon.dll?" #production
    #aeon = "https://aeon-test-mssa.library.yale.edu/aeon.dll?" #test
    aeon = get_aeon_endpoint
    #
    #start here,get fields, get mfhd and apply a link underline styling, and try for P&D as well
    action = 10
    form = 20
    value = "GenericRequestMonograph"
    value = "GenericRequestPD" if get_one_value(doc["collection_ss"]) == "Prints and Drawings"
    site = "YCBA"
    callnumber = get_one_value(doc["callnumber_ss"])
    title = get_one_value(doc["title_ss"]).gsub("'","%27")
    author = get_one_value(doc["author_ss"]).gsub("'","%27")
    publishdate = get_one_value(doc["publishDateFacet_ss"])
    physical = get_one_value(doc["physical_ss"])
    location = map_collection(doc["collection_ss"])
    url = get_one_value(doc["url_ss"])
    mfhd = get_mfhd(doc["url_ss"])

    #for Prints and Drawings only
    collection = get_one_value(doc["collection_ss"])
    if collection == "Prints and Drawings" #this is always true
      physical = get_one_value(doc["format_ss"])
      #location = get_one_value(doc["location_ss"]) #removing as P&D not on view won't have detailed location
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

    anchor_tag = "<a href='#{aeon}' target='_blank'>Request</a>"

    return anchor_tag.html_safe
  end

  def create_aeon_link_callnumber(doc,callnumber,mfhd_id)
    aeon = get_aeon_endpoint
    #
    #start here,get fields, get mfhd and apply a link underline styling, and try for P&D as well
    action = 10
    form = 20
    value = "GenericRequestMonograph"
    site = "YCBA"
    title = get_one_value(doc["title_ss"]).gsub("'","%27")
    author = get_one_value(doc["author_ss"]).gsub("'","%27")
    publishdate = get_one_value(doc["publishDateFacet_ss"])
    physical = get_one_value(doc["physical_ss"])
    location = map_collection(doc["collection_ss"])
    url = get_one_value(doc["url_ss"])

    #for Prints and Drawings only
    collection = get_one_value(doc["collection_ss"])
    if collection == "Prints and Drawings"
      physical = get_one_value(doc["format_ss"])
      location = get_one_value(doc["location_ss"])
      mfhd = ""
    end
    if collection == "Rare Books and Manuscripts"
      callnumber = callnumber.gsub("+","%2B")
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
    aeon += "mfhdID=#{mfhd_id}&"
    aeon += "EADNumber=#{url}"

    anchor_tag = "<a href='#{aeon}' target='_blank'>Request</a>"

    return anchor_tag.html_safe
  end

  def get_one_value(field)
    defined?(field) && defined?(field[0]) ? field[0] : ""
  end

  def map_collection(field)
    return "bacrb" if get_one_value(field)=="Rare Books and Manuscripts"
    return "bacref" if get_one_value(field)=="Reference Library"
    return "bacpd" if get_one_value(field)=="Prints and Drawings"
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

  def mfhd_path(r)
    r["record"][0]["items"][0]["mfhdid"]
  end
  def parse_mfhd(r)
    begin
      mfhd = mfhd_path(r)
    rescue
      mfhd = ""
    end
    return mfhd
  end
  #end aeon methods
  #deprecated
  def get_frame_link_label(doc)
    c = doc["collection_ss"][0]
    if c == "Frames"
      label = "Link to Framed Image:"
    else
      label = "Link to Frame:"
    end
  end
  #deprecated
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
  def handle_frames options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

    links = []
    options[:value].each {  |link|
      id = link.split("|")[0]
      bnum = link.split("|")[1]
      links.append(link_to bnum, "/catalog/tms:#{id}", target: '_blank')
    }

    links.join('<br/>').html_safe
  end


  def query_solr(solr,field,value)
    response = solr.post "select", :params => {
        :fq=>"#{field}:\"#{value}\""
    }
    return nil if response['response']['docs'].length == 0
    response['response']['docs'][0]["id"]
  end


  #code not used in favor of direct link to ilsnumber_ss facet
=begin
  def get_ycba_objects(doc)
    solr_config = Rails.application.config_for(:blacklight)
    solr = RSolr.connect :url => solr_config["url"]
    resp,cnt = get_solr_response(solr,"ilsnumber_ss",doc["id"].gsub("orbis:",""))
    html = ""

    resp_sorted = resp.sort_by { |doc|
      if doc["auth_author_display_ss"]
        doc["auth_author_display_ss"][0]
      else
        "ZZZZZ"
      end
    }

    resp_sorted.each.with_index do |doc, i|
      link = doc["id"]
      display = Array.new
      if i==0 and cnt > 250
        html += "#{cnt} referenced works. only 250 displayed."
      else
        display.push(doc["author_ss"][0]) if doc["author_ss"]
        display.push(doc["title_short_ss"][0].chomp(":").chomp("/").chomp(".")) if doc["title_short_ss"]
        display.push(doc["publishDate_ss"][0]) if doc["publishDate_ss"]
        html += link_to display.join(" "),"#{request.protocol}#{request.host_with_port}/catalog/#{link}",target: :_blank, rel: "nofollow"
      end
      html += "</br>"
      #html += link_to display.join(" "),"#{request.protocol}#{request.host_with_port}/catalog/#{link}",target: :_blank, rel: "nofollow"
    end
    #puts html
    return html.html_safe
  end

  def get_solr_response(solr,field,value)
    response = solr.post "select", :params => {
        :fq=>"#{field}:\"#{value}\"", :rows=>250
    }
    return [], 0 if response['response']['docs'].length == 0
    return response['response']['docs'], response['response']['numFound']
  end
=end

  def link_to_referenced_ycba_objects(id)
    num_found = get_num_found("ilsnumber_ss",id.gsub("orbis:",""))
    prelabel = "View the"
    label = "Works referenced in this item"
    label = "Work referenced in this item" if num_found == 1
    link_to "#{prelabel} #{num_found} #{label}","#{request.protocol}#{request.host_with_port}/?utf8=✓&search_field=Fielded&q=ilsnumber_ss%3A#{id.gsub("orbis:","")}",target: :_blank, rel: "nofollow"
  end

  def get_num_found(field,value)
    solr_config = Rails.application.config_for(:blacklight)
    solr = RSolr.connect :url => solr_config["url"]
    response = solr.post "select", :params => {
        :fq=>"#{field}:\"#{value}\"", :rows=>0
    }
    response['response']['numFound']
  end

  def referenced_works?(doc)
    solr_config = Rails.application.config_for(:blacklight)
    solr = RSolr.connect :url => solr_config["url"]
    response = solr.post "select", :params => {
        :fq=>"ilsnumber_ss:\"#{doc["id"].gsub("orbis:","")}\"", :rows=>0
    }
    return false if response['response']['numFound'] == 0
    return true
  end

  def render_ycba_item_header(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    fontsize = options.fetch(:fontsize, "12px")
    document ||= @document

    header = Array.new
    header.push(content_tag(tag, document["author_ss"][0], style: "font-size: #{fontsize}")) if document["author_ss"]
    header.push(content_tag(tag, document["title_short_ss"][0].chomp(":").chomp("/").chomp("."), style: "font-weight: bold; font-size: #{fontsize}")) if document["title_short_ss"]
    header.push(content_tag(tag, document["publishDate_ss"][0], style: "font-size: #{fontsize}")) if document["publishDate_ss"]

    fullheader = header.join(", ").html_safe
    content_tag("div", fullheader, style:"text-align:center", itemprop: "name", id: "fullheader")
  end

  def get_download_array_from_manifest
    manifest = "https://manifests.collections.yale.edu/ycba/obj/" + @document['id'].split(":")[1] if @document['recordtype_ss'][0] == "lido"
    manifest = "https://manifests.collections.yale.edu/ycba/orb/" + @document['id'].split(":")[1] if @document['recordtype_ss'][0] == "marc"
    #puts "MANIFEST:"+manifest;
    download_array = Array.new()
    begin
      json = JSON.load(URI.open(manifest))
    rescue
      return download_array,true
    end
    items = json["items"]
    restricted = false
    items.each_with_index do |item,index|
      count = (index + 1).to_s
      caption = ""
      jpeg = ""
      tiff = ""
      caption = item["label"]["en"][0] if item && item["label"] && item["label"]["en"] && item["label"]["en"][0]
      jpeg = item["items"][0]["items"][0]["body"]["id"] if item && item["items"] && item["items"][0] && item["items"][0]["items"] && item["items"][0]["items"][0] && item["items"][0]["items"][0]["body"] && item["items"][0]["items"][0]["body"]["id"]
      tiff = item["rendering"][0]["id"] if item && item["rendering"] && item["rendering"][0] && item["rendering"][0]["id"]
      if index == 0
        height = item["height"] if item && item["height"]
        width = item["width"] if item && item["width"]
        restricted = true unless height > 480 || width > 480
      end
      download_array[index] = [count,caption,jpeg,tiff,item["width"]]
    end
    #puts download_array.inspect

    return download_array,restricted
  end

  def manifest_thumb?
    manifest = "https://manifests.collections.yale.edu/ycba/obj/" + @document['id'].split(":")[1] if @document['recordtype_ss'][0] == "lido"
    manifest = "https://manifests.collections.yale.edu/ycba/orb/" + @document['id'].split(":")[1] if @document['recordtype_ss'][0] == "marc"
    #puts "MANIFEST:"+manifest;
    download_array = Array.new()
    begin
      json = JSON.load(URI.open(manifest))
    rescue
      return true
    end
    height = json["items"][0]["height"]
    width = json["items"][0]["width"]
    if height <= 480 and width <= 480
      return true
    else
      return false
     end
  end

  def manifest?
    url = "https://manifests.collections.yale.edu/ycba/obj/" + @document['id'].split(":")[1] if @document['recordtype_ss'][0] == "lido"
    url = "https://manifests.collections.yale.edu/ycba/orb/" + @document['id'].split(":")[1] if @document['recordtype_ss'][0] == "marc"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    begin
      j = JSON.parse(response)
    rescue
      return false
    end
    return true
  end

  def document_field_exists?(doc,field)
    return false if doc[field].nil? or !doc.has_key?(field) or doc[field][0]==""
    return true
  end

  def handle_lido_collections options={}
    #assuming only 1 collection for lido
    if options[:document][:callnumber_ss] && options[:document][:callnumber_ss][0].start_with?("L")
      return "#{options[:value][0]} (Loan)"
    else
      return options[:value][0]
    end
  end

  def jsonld(doc)
    jsonld_doc = Hash.new
    jsonld_doc["@context"] = "https://schema.org"
    jsonld_doc["@type"] = "VisualArtwork" if doc[:recordtype_ss][0] == "lido"
    jsonld_doc["@type"] = "CreativeWork" if doc[:recordtype_ss][0] == "marc"
    jsonld_doc["name"] = doc["title_ss"][0] unless doc["title_ss"].nil?
    jsonld_doc["image"] = doc["manifest_thumbnail_ss"][0] unless doc["manifest_thumbnail_ss"].nil?

    creator = Hash.new
    creator["@type"] = "Person"
    creator["name"] = doc["loc_naf_author_ss"][0] unless doc["loc_naf_author_ss"].nil?
    if doc[:recordtype_ss][0] == "marc"
      jsonld_doc["creator"] = creator unless doc["loc_naf_author_ss"].nil?
    end
    if doc[:recordtype_ss][0] == "lido"
      jsonld_doc["artist"] = creator unless doc["loc_naf_author_ss"].nil?
    end
    return jsonld_doc.to_json.html_safe
  end

  #deprecated in favor of webpack
=begin
  def mirador3_config(manifest)
  config = '{
      "id": "mirador3",
      "selectedTheme": "light",
      "manifests": {
          "manifest": {
              "provider": "Yale Center for British Art"
          }
      },
      "window": {
          "allowClose": false,
          "allowFullscreen": true,
          "allowMaximize": false
      },
      "windows": [
          {
              "loadedManifest": "' + manifest + '",
              "canvasIndex": 0,
              "thumbnailNavigationPosition": "far-bottom",
              "allowClose": false

          }
      ],
      "workspaceControlPanel": {
          "enabled": false
      },
      "workspace": {
          "showZoomControls": true
      }
    }'
    puts config
    return config.html_safe
  end
=end
  #deprecated in favor of webpack
=begin
  def mirador3t_config(manifest)
    config = '{
      "id": "mirador3t",
      "selectedTheme": "light",
      "manifests": {
          "manifest": {
              "provider": "Yale Center for British Art"
          }
      },
      "window": {
          "allowClose": false,
          "allowFullscreen": false,
          "allowMaximize": false
      },
      "windows": [
          {
              "loadedManifest": "' + manifest + '",
              "canvasIndex": 0,
              "thumbnailNavigationPosition": "off",
              "allowClose": false

          }
      ],
      "thumbnailNavigation": {
          "defaultPosition": "off"
      },
      "workspaceControlPanel": {
          "enabled": false
      },
      "workspace": {
          "showZoomControls": true
      },
      "osdConfig": {
          "showNavigationControl": true
      }
    }'
    puts config
    return config.html_safe
  end
=end
end