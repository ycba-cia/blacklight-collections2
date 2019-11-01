class PrintController < ApplicationController
  include PrintHelper

  def show
    @id = params[:id]
    @size = params[:size]
    @images = print_images(@id)
    @document = get_solr_doc(@id)
    @item_data = ""
    if @document["recordtype_ss"][0] == "lido"
      @item_data += print_newline_fields("Creator:","author_ss")
      @item_data += print_fields("Title:","title_ss")
      @item_data += print_fields("Date:","publishDate_ss")
      @item_data += print_fields("Medium:","format_ss")
      @item_data += print_fields("Dimensions:","physical_ss")
      @item_data += print_fields("Inscription(s)/Marks/Lettering:","description_ss")
      @item_data += print_fields("Credit Line:","credit_line_ss")
      @item_data += print_fields("Accession Number:","callnumber_ss")
      @item_data += print_fields("Classification:","type_ss")
      @item_data += print_fields("Collection:","collection_ss")
      @item_data += print_sep_fields("Subject Terms:","topic_ss")
      @item_data += print_sep_fields("Associated Places:","topic_subjectPlace_ss")
      @item_data += print_sep_fields("Associated People:","topic_subjectPeople_ss")
      @item_data += print_fields("Curatorial Comment:","curatorial_comment_ss")
      @item_data += print_newline_fields("Exhibition History:","exhibition_history_ss")
      @item_data += print_newline_fields("Publications:","citation_txt")
      @item_data += print_fields("Link:","url_ss")
    else

    end
    render layout: false
  end
end