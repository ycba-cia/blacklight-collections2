class PrintController < ApplicationController
  include PrintHelper

  def show
    @id = params[:id]
    @size = params[:size]
    @index = params[:index]
    @caption = params[:caption]
    @images = print_images(@id,@index)
=begin
    #stubbed get_solr_doc rather then this kluge, keeping for reference
    #puts "protocol:#{request.protocol}" # http://
    #puts "host:#{request.host_with_port}" # test.host
    if request.host_with_port == "test.host"
      if @id.start_with?("tms")
        @document = JSON.parse(File.open("spec/fixtures/dort.json","rb").read)
      end
      if @id.start_with?("orbis")
        @document = JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read)
      end
    else
      @document = get_solr_doc(@id,request.protocol,request.host_with_port)
    end
=end
    @document = get_solr_doc(@id,request.protocol,request.host_with_port)

    if @document["recordtype_ss"][0] == "lido" and @size != "2"
      @item_data = ""
      @item_data += print_newline_fields("Creator:","author_ss")
      @item_data += print_fields("Title:","title_ss")
      @item_data += print_string("Caption:",@caption)
      @item_data += print_fields("Date:","publishDate_ss")
      @item_data += print_fields("Materials & Techniques:","format_ss")
      @item_data += print_fields("Dimensions:","physical_ss")
      @item_data += print_fields("Inscription(s)/Marks/Lettering:","description_ss")
      @item_data += print_fields("Credit Line:","credit_line_ss")
      @item_data += print_fields_default_empty("Copyright Status:","ort_ss","Unknown")
      @item_data += print_fields("Accession Number:","callnumber_ss")
      @item_data += print_fields("Classification:","type_ss")
      @item_data += print_fields("Collection:","collection_ss")
      @item_data += print_sep_fields("Subject Terms:","topic_ss")
      @item_data += print_sep_fields("Associated Places:","topic_subjectPlace_ss")
      @item_data += print_sep_fields("Associated People:","topic_subjectPeople_ss")
      @item_data += print_fields("Currently On View:","onview_ss")
      @item_data += print_fields("Curatorial Comment:","curatorial_comment_ss")
      @item_data += print_newline_fields("Exhibition History:","exhibition_history_ss")
      @item_data += print_newline_fields("Publications:","citation_txt")
      @item_data += print_fields("Gallery Label:","gallery_label_ss")
      @item_data += print_fields("Provenance:","provenance_ss")
      @item_data += print_fields("Link:","url_ss")
    end


    if @document["recordtype_ss"][0] == "marc" and @size != "2"
      @item_data = ""
      @item_data += print_newline_fields("Creator:","author_ss")
      @item_data += print_fields("Title:","title_ss")
      @item_data += print_fields("Alternate Title(s):","title_alt_ss")
      @item_data += print_string("Caption:",@caption)
      @item_data += print_fields("Edition:","edition_ss")
      @item_data += print_newline_fields("Published / Created:","publisher_ss")
      @item_data += print_fields("Physical Description:","physical_ss")
      @item_data += print_fields("Collection:","collection_ss")
      @item_data += print_newline_fields("Call Number:","callnumber_ss")
      @item_data += print_fields("Credit Line:","credit_line_ss")
      @item_data += print_fields_default_empty("Copyright Status:","ort_ss","Unknown")
      @item_data += print_fields("Full Orbis Record:","orbis_link_ss")
      @item_data += print_fields("Related Content:","resourceURL_ss")
      @item_data += print_fields("Classification:","type_ss")
      @item_data += print_fields("Scale:","cartographic_detail_ss")
      @item_data += print_fields("Notes:","description_ss")
      @item_data += print_fields("Contents:","marc_contents_ss")
      @item_data += print_fields("Currently On View:","onview_ss")
      @item_data += print_newline_fields("Exhibition History:","exhibition_history_ss")
      @item_data += print_sep_fields("Subject Terms:","topic_ss")
      @item_data += print_sep_fields("Form/Genre:","form_genre_ss")
      @item_data += print_sep_fields("Contributors:","author_additional_ss")
    end

    if @document["recordtype_ss"][0] == "lido" and @size == "2"
      #example tms:5005
      @item_data = ""
      @item_data += print_newline_fields("Creator:","author_ss")
      @item_data += print_fields("Title:","title_ss")
      @item_data += print_fields("Date:","publishDate_ss")
      @item_data += print_fields("Materials & Techniques:","format_ss")
      @item_data += print_fields("Dimensions:","physical_ss")
      @item_data += print_fields("Credit Line:","credit_line_ss")
      @item_data += print_fields_default_empty("Copyright Status:","ort_ss","Unknown")
      @item_data += print_fields("Accession Number:","callnumber_ss")
      @item_data += print_fields("Gallery Label:","gallery_label_ss")
    end

    if @document["recordtype_ss"][0] == "marc" and @size == "2"
      @item_data = ""
      @item_data += print_newline_fields("Creator:","author_ss")
      @item_data += print_fields("Title:","title_ss")
      @item_data += print_fields("Alternate Title(s):","title_alt_ss")
      @item_data += print_string("Caption:",@caption)
      @item_data += print_fields("Edition:","edition_ss")
      @item_data += print_newline_fields("Published / Created:","publisher_ss")
      @item_data += print_fields("Physical Description:","physical_ss")
      @item_data += print_fields("Collection:","collection_ss")
      @item_data += print_newline_fields("Call Number:","callnumber_ss")
      @item_data += print_fields("Credit Line:","credit_line_ss")
      @item_data += print_fields_default_empty("Copyright Status:","ort_ss","Unknown")
      @item_data += print_fields("Full Orbis Record:","orbis_link_ss")
      @item_data += print_fields("Related Content:","resourceURL_ss")
      @item_data += print_fields("Classification:","type_ss")
      @item_data += print_fields("Scale:","cartographic_detail_ss")
      @item_data += print_fields("Notes:","description_ss")
      @item_data += print_fields("Contents:","marc_contents_ss")
      @item_data += print_fields("Currently On View:","onview_ss")
      @item_data += print_newline_fields("Exhibition History:","exhibition_history_ss")
      @item_data += print_sep_fields("Subject Terms:","topic_ss")
      @item_data += print_sep_fields("Form/Genre:","form_genre_ss")
      @item_data += print_sep_fields("Contributors:","author_additional_ss")
    end

    if @document["recordtype_ss"][0] == "archival" and @size != "2"
      @item_data = ""
      @item_data += print_newline_fields("Call Number:","arcCallNumber_ss")
      @item_data += print_newline_fields("Finding Aid Title:","arcFindingAidTitle_ss")
      @item_data += print_newline_fields("Title:","title_ss")
      @item_data += print_newline_fields("Creator:","creator_ss")
      @item_data += print_fields("Date:","date_ss")
      @item_data += print_fields("Classification:","type_ss")
      @item_data += print_fields("Series:","arcSeries_ss")
      @item_data += print_fields("Part of Collection:","arcContainerGrouping_ss")
      @item_data += print_sep_fields("Subject Terms:","topic_ss")
      @item_data += print_fields("Conditions Governing Use:","useRestrict_ss")
      @item_data += print_string("Collection PDF:",get_resource_pdf(@document))
    end

    if @document["recordtype_ss"][0] == "archival" and @size == "2"
      @item_data = ""
      @item_data += print_newline_fields("Call Number:","arcCallNumber_ss")
      @item_data += print_newline_fields("Finding Aid Title:","arcFindingAidTitle_ss")
      @item_data += print_newline_fields("Title:","title_ss")
      @item_data += print_newline_fields("Creator:","creator_ss")
      @item_data += print_fields("Date:","date_ss")
      @item_data += print_fields("Classification:","type_ss")
      @item_data += print_fields("Series:","arcSeries_ss")
      @item_data += print_fields("Part of Collection:","arcContainerGrouping_ss")
      @item_data += print_sep_fields("Subject Terms:","topic_ss")
      @item_data += print_fields("Conditions Governing Use:","useRestrict_ss")
      @item_data += print_string("Collection PDF:",get_resource_pdf(@document))
    end

    if @document["recordtype_ss"][0] == "artists" and @size != "2"
      @item_data = ""
      @item_data += print_fields("Creator:","locnaf_ss")
      @item_data += print_fields("Date:","displaydate_ss")
      @item_data += print_newline_fields("Objects:","objects_ss")
    end

    if @document["recordtype_ss"][0] == "artists" and @size == "2"
      @item_data = ""
      @item_data += print_fields("Creator:","locnaf_ss")
      @item_data += print_fields("Date:","displaydate_ss")
      @item_data += print_newline_fields("Objects:","objects_ss")
    end

    render layout: false
  end
end