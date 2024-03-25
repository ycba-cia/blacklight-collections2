# frozen_string_literal: true
class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride

  include Blacklight::Catalog

  before_action :getID, only: [:show]

  #ERJ: for reference https://github.com/projectblacklight/blacklight/wiki/Adding-new-document-actions

  def cite
    idd = params[:id]
    document = SolrDocument.find(idd)
    @apa = document.getAPA
    @mla = document.getMLA
    respond_to do |format|
      format.html
    end
  end

  def getID
    @id = params[:id]
  end

  rescue_from Blacklight::Exceptions::RecordNotFound do
    render 'record_not_found', status: 404
  end

  rescue_from Blacklight::Exceptions::ECONNREFUSED do
    render 'econnrefused'
  end

  configure_blacklight do |config|
    #config.view.gallery.partials = [:image_index]
    config.view.masonry.partials = [:compact_index]
    config.view.masonry.default = true
    config.view.masonry.icon_class = 'glyphicon-th'
    #config.view.slideshow.partials = [:compact_index]

    config.index.thumbnail_method = :thumb
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    #config.show.partials.insert(1, :mirador3)

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'


    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [100,50,15]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    # config.default_document_solr_params = {
    #  qt: 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # fl: '*',
    #  #rows: 1,
    #  # q: '{!term f=id v=$id}'
    # }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_ss'
    config.index.display_type_field = 'recordtype_ss'

    # solr field configuration for document/show views
    #config.show.title_field = 'title_ss'
    config.show.display_type_field = 'recordtype_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    config.add_facet_field 'collection_ss', :label => 'Collection', :limit => 20, :collapse => false, :sort => 'count'
    config.add_facet_field 'loc_naf_author_ss', label: 'Creator', :limit => 20
    config.add_facet_field 'earliestDate_is', :label => 'Date', single: true,range: { segments: false }
    config.add_facet_field 'detailed_onview_ss', :label => 'On-site Access'
    config.add_facet_field 'rights_ss',label: 'Image Use'
    config.add_facet_field 'has_image_ss', helper_method: 'capitalize', :label => 'Image Available'
    y = Time.now.year
    config.add_facet_field 'date_entered_is', :label => 'New Additions', query: { past_year: { label: "#{y-1}-#{y}",fq: "date_entered_is:[#{y-1} TO #{y}]"}}
    config.add_facet_field 'type_ss', :label => 'Classification', :limit => 20
    config.add_facet_field 'author_gender_ss', :label => 'Creator Gender'
    config.add_facet_field 'title_collective_ss', :label => 'Collective Title', :limit => 20
    config.add_facet_field 'era_ss', :label => 'Period'
    config.add_facet_field 'auth_format_ss', :label => 'Materials & Techniques', :limit => 20
    config.add_facet_field 'physical_heightValue_is', :label => 'Height [cm]',range: { segments: false }
    config.add_facet_field 'physical_widthValue_is', :label => 'Width [cm]',range: { segments: false }
    config.add_facet_field 'object_name_ss', :label => 'Work Type', :limit => 20
    config.add_facet_field 'genre_name_ss', :label => 'Genre', :limit => 20
    config.add_facet_field 'topic_ss', :label => 'Subject Terms', :limit => 20
    config.add_facet_field 'subject_period_ss', :label => 'Subject Period', :limit => 20
    config.add_facet_field 'geographic_ss', :label => 'Associated Places', :limit => 20
    config.add_facet_field 'topic_subjectActor_ss', :label => 'Associated People', :limit => 20
    config.add_facet_field 'exhibition_history_ss', :label => 'Exhibition History', :limit => 20
    config.add_facet_field 'credit_line_ss', :label => 'Credit Line', :limit => 20
    config.add_facet_field 'language_name_ss', :label => 'Language', :limit => 20 #marc only

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!



    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # config.add_index_field 'title_t', :label => 'Title'
    #config.add_index_field 'type_txt', :label => 'Type'
    config.add_index_field 'qualified_author_ss', :label => 'Creator', if: :display_lido_field?
    config.add_index_field 'loc_naf_author_ss', :label => 'Creator', if: :display_marc_field?
    config.add_index_field 'publishDate_txt', label: "Date"
    config.add_index_field 'format_txt', :label => 'Materials & Techniques'
    config.add_index_field 'physical_txt', :label => 'Dimensions', if: :display_lido_field?
    config.add_index_field 'physical_ss', :label => 'Physical Description', if: :display_marc_field?
    config.add_index_field 'collection_txt', :label => 'Collection', if: :display_objects_field?
    config.add_index_field 'credit_line_txt', :label => 'Credit Line'
    config.add_index_field 'name_ss', :label => 'Artist'
    config.add_index_field 'gender_ss', :label => 'Gender'
    config.add_index_field 'tms_birthdate_ss', :label => 'Birth'
    config.add_index_field 'tms_deathdate_ss', :label => 'Death'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    #config.add_show_field 'title_t', :label => 'Title'

    break_separator = {words_connector: ' <br/> ', last_word_connector: ' <br/> ', two_words_connector: ' <br/> '}
    comma_separator = {words_connector: ', ', last_word_connector: ', ', two_words_connector: ', '}

    #lido fields in detailed view
    #config.add_show_field 'author_ss', :label => 'Creator', link_to_search: true, separator_options: break_separator, helper_method: 'handle_qualifiers', if: :display_lido_field?
    config.add_show_field 'loc_naf_author_ss', :label => 'Creator', link_to_search: true, separator_options: break_separator, helper_method: 'handle_qualifiers2', if: :display_lido_field?
    config.add_show_field 'titles_primary_ss', :label => 'Title', helper_method: 'render_titles_all', if: :display_lido_field?
    config.add_show_field 'titles_former_ss', :label => 'Former Title(s)', helper_method: 'render_titles_all', if: :display_lido_field?
    config.add_show_field 'titles_additional_ss', :label => 'Additional Title(s)', helper_method: 'render_titles_all', if: :display_lido_field?
    config.add_show_field 'title_collective_ss', :label => 'Part Of', helper_method: 'render_parent', :limit => 20
    config.add_show_field 'publishDate_ss', :label => 'Date', if: :display_lido_field?
    config.add_show_field 'format_ss', :label => 'Materials & Techniques', if: :display_lido_field?
    config.add_show_field 'physical_ss',  :label => 'Dimensions', separator_options: comma_separator, if: :display_lido_field?
    config.add_show_field 'description_ss', :label => 'Inscription(s)/Marks/Lettering', helper_method: 'render_citation', if: :display_lido_field?
    config.add_show_field 'credit_line_ss', :label => 'Credit Line', if: :display_lido_field?
    config.add_show_field 'dummy_ort_lido_acc', :accessor => 'dummy_ort_lido_acc', :label => 'Copyright Status', helper_method: 'render_copyright_status', if: :display_lido_accessor_field?
    config.add_show_field 'callnumber_ss', :label => 'Object Number', if: :isLidoLoan?
    config.add_show_field 'callnumber_txt', :label => 'Accession Number', unless: :isLidoLoan?
    config.add_show_field 'type_ss', :label => 'Classification', if: :display_lido_field?
    config.add_show_field 'collection_ss', :label => 'Collection', helper_method: 'handle_lido_collections', if: :display_lido_field?
    config.add_show_field 'topic_ss', :label => 'Subject Terms', link_to_search: 'topic_facet', separator_options: break_separator, helper_method: 'sort_values_and_link_to_facet_frames', if: :display_lido_field?
    config.add_show_field 'topic_subjectPlace_ss', :label => 'Associated Places', link_to_search: true, separator_options: break_separator, helper_method: 'sort_values_and_link_to_facet', if: :display_lido_field?
    config.add_show_field 'topic_subjectActor_ss', :label => 'Associated People', link_to_search: true, separator_options: break_separator, if: :display_lido_field?
    config.add_show_field 'topic_frameAlteration_ss', :label => 'Frame Alteration', link_to_search: true, separator_options: break_separator, if: :display_lido_field?
    config.add_show_field 'topic_frameStatus_ss', :label => 'Frame Status', link_to_search: true, separator_options: break_separator, if: :display_lido_field?
    config.add_show_field 'topic_frameOrnament_ss', :label => 'Frame Ornament', separator_options: break_separator, if: :display_lido_field?
    config.add_show_field 'topic_frameFeature_ss', :label => 'Frame Feature', link_to_search: true, separator_options: break_separator, if: :display_lido_field?
    config.add_show_field 'topic_frameStyle_ss', :label => 'Frame Style', link_to_search: true, separator_options: break_separator, if: :display_lido_field?
    config.add_show_field 'detailed_onview_ss',helper_method: 'render_aeon_from_access', :label => 'Access', if: :display_lido_field?
    config.add_show_field 'curatorial_comment_ss', :label => 'Curatorial Comment', helper_method: 'combine_curatorial_comments', if: :display_lido_field?
    config.add_show_field 'exhibition_history_ss', :label => 'Exhibition History', helper_method: 'render_exhibitions', if: :display_lido_field?
    config.add_show_field 'citation_txt', :label => 'Publications', helper_method: 'render_tms_citation_presorted', if: :display_lido_field?
    config.add_show_field 'url_ss', :label => 'Link', helper_method: 'render_as_link', if: :display_lido_field?

    #marc fields in detailed view (note: accessors needed when field both in marc and lido, and special display_marc_accessor_field method to not show empty fields)
    config.add_show_field 'loc_naf_author_acc', :accessor => 'loc_naf_author_acc',  :label => 'Creator', helper_method: 'link_to_author', separator_options: break_separator, if: :display_marc_accessor_field?
    #config.add_show_field 'title_acc', :accessor => 'title_acc', :label => 'Title', helper_method: 'add_alt_title', if: :display_marc_accessor_field?
    #config.add_show_field 'title_alt_ss', :label => 'Alternate Title(s)', helper_method: 'add_alt_title_alt', separator_options: break_separator, if: :display_marc_field?
    config.add_show_field 'title_acc', :accessor => 'title_acc', :label => 'Title(s)', helper_method: 'render_titles_all', if: :display_marc_accessor_field?
    config.add_show_field 'titles_former_acc', :accessor => 'titles_former_acc', :label => 'Former Title(s)', helper_method: 'render_titles_all', if: :display_marc_accessor_field?
    config.add_show_field 'titles_additional_acc', :accessor => 'titles_additional_acc', :label => 'Additional Title(s)', helper_method: 'render_titles_all', if: :display_marc_accessor_field?
    config.add_show_field 'edition_ss', label: 'Edition', helper_method: 'add_alt_edition', if: :display_marc_field?
    config.add_show_field 'publisher_ss', :label => 'Published/Created', helper_method: 'add_alt_publisher', separator_options: break_separator, if: :display_marc_field?
    config.add_show_field 'physical_acc', accessor: 'physical_acc', label: 'Physical Description', if: :display_marc_accessor_field?
    #holdings inserted here, see _show_marc_html.erb
    config.add_show_field 'dummy_ort_marc_acc', :accessor => 'dummy_ort_marc_acc', :label => 'Copyright Status', helper_method: 'render_copyright_status', if: :display_marc_accessor_field?
    config.add_show_field 'orbis_link_acc', accessor: 'orbis_link_acc', :label => 'Full Orbis Record', helper_method: 'render_as_link', if: :display_marc_accessor_field?
    config.add_show_field 'resourceURL_ss', :label => 'Related Content', helper_method: 'render_related_content', if: :render_related_content?
    config.add_show_field 'type_acc', accessor: 'type_acc', :label => 'Classification', if: :display_marc_accessor_field?
    config.add_show_field 'cartographic_detail_ss', :label => 'Scale', if: :display_marc_field?
    config.add_show_field 'note_acc', accessor: 'note_acc', :label => 'Notes', helper_method: 'add_alt_description', if: :display_marc_accessor_field?
    #config.add_show_field 'marc_contents_ss', label: 'Contents', helper_method: 'format_contents', if: :display_marc_field? #Note: moved to tab
    config.add_show_field 'exhibition_history_acc', accessor: 'exhibition_history_acc', :label => 'Exhibition History', helper_method: 'render_exhibitions', if: :display_marc_field?
    config.add_show_field 'topic_acc', accessor: 'topic_acc', :label => 'Subject Terms', link_to_search: 'topic_facet', separator_options: break_separator, helper_method: 'sort_values_and_link_to_topic_no_pipes', if: :display_marc_accessor_field?
    config.add_show_field 'form_genre_ss', :label => 'Form/Genre', link_to_search: true, separator_options: break_separator, if: :display_marc_field?
    config.add_show_field 'author_additional_ss', :label => 'Contributors', link_to_search: true, separator_options: break_separator, if: :display_marc_field?
    #config.add_show_field 'cite_as', accessor: 'cite_as', :label => 'Cite As', if: :display_marc_accessor_field? #don't display per #18

    #artists field
    config.add_show_field 'name_ss', :label => 'Artist', separator_options: break_separator, if: :display_artists_field?
    config.add_show_field 'gender_ss', :label => 'Gender', separator_options: break_separator, if: :display_artists_field?
    config.add_show_field 'tms_birthdate_ss', :label => 'Birth Date', separator_options: break_separator, helper_method: 'render_birthdate', if: :display_artists_field?
    config.add_show_field 'tms_deathdate_ss', :label => 'Death Date', separator_options: break_separator, helper_method: 'render_deathdate', if: :display_artists_field?
    config.add_show_field 'birthplace_ss', :label => 'Birth Place', link_to_search: true, separator_options: break_separator, helper_method: 'render_luxplace', if: :display_artists_field?
    config.add_show_field 'deathplace_ss', :label => 'Death Place', link_to_search: true, separator_options: break_separator, helper_method: 'render_luxplace', if: :display_artists_field?
    config.add_show_field 'activity_ss', :label => 'Activity Place', link_to_search: true, separator_options: break_separator, helper_method: 'render_luxplace', if: :display_artists_field?
    config.add_show_field 'residence_ss', :label => 'Residence', link_to_search: true, separator_options: break_separator, helper_method: 'render_luxplace', if: :display_artists_field?
    config.add_show_field 'objects_ss', :label => 'Artwork', link_to_search: true, separator_options: break_separator, helper_method: 'render_artwork', if: :display_artists_field?

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'simple_search', label: 'Simple Search'

    config.add_search_field('All Fields') do |field|
      #field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_parameters = {
        qf: [
            'author_txt^10',
            'title_txt^4',
            'topic_txt^4',
            'publishDate_txt',
            'format_txt',
            'physical_txt',
            'description_txt',
            'credit_line_txt',
            'callnumber_txt',
            'type_txt',
            'collection_txt',
            'geographic_txt',
            'topic_subjectActor_txt^3',
            'title_alt_txt',
            'publisher_txt',
            'resourceURL_txt',
            'cartographic_detail_txt',
            'marc_contents_txt',
            'form_genre_txt',
            'author_additional_txt',
            'exhibition_history_txt',
            'curatorial_comment_txt',
            'curatorial_comment_auth_txt',
            'curatorial_description_txt',
            'curatorial_description_auth_txt',
            'pub_cat_entry_txt',
            'pub_cat_entry_auth_txt',
            'gallery_label_txt',
            'gallery_label_auth_txt'
        ]
      }
    end


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('Title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      #field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_parameters = {
        qf: ['title_txt^10'],
        pf: ['title_txt^20']
      }
    end

    config.add_search_field('Creator') do |field|
      #field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_parameters = {
        qf: ['author_txt^10'],
        pf: ['author_txt^20']
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('Subject Terms') do |field|
      #field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      #field.qt = 'search'
      field.solr_parameters = {
          qf: ['topic_txt^10'],
          pf: ['topic_txt^20']
      }
    end

    config.add_search_field('Call Number') do |field|
      field.solr_parameters = {
          qf: ['callnumber_txt^10']
      }
    end

    config.add_search_field('Search Provenance') do |field|
      field.solr_parameters = {
          qf: ['provenance_txt^10'],
          pf: ['provenence_txt^20']
      }
    end

    config.add_search_field('Fielded') do |field|
      field.solr_parameters = {
          qt: '/query'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', label: 'relevance'
    #config.add_sort_field 'pub_date_sort desc, title_sort asc', label: 'year'
    #config.add_sort_field 'author_sort asc, title_sort asc', label: 'author'
    #config.add_sort_field 'title_sort asc, pub_date_sort desc', label: 'title'
    config.add_sort_field 'collection_sort_s asc, score desc', label: 'collection'
    config.add_sort_field 'score desc', label: 'relevance'
    config.add_sort_field 'author_sort_s asc, score desc', label: ' artist (A-Z)'
    config.add_sort_field 'earliestDate_i asc, score desc', label: 'date'
    config.add_sort_field 'title_s asc, score desc', label: 'title (A-Z)'



    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    # disable until solrconfig.xml access found for ycba_collections_search
    #config.autocomplete_enabled = true
    #config.autocomplete_path = 'suggest'

  end

  #ERJ maybe next 2 methods belong in a helper
  def display_marc_field?(context, doc)
    doc['recordtype_ss'] and doc['recordtype_ss'][0].to_s == 'marc'
  end

  def display_lido_field?(context, doc)
    doc['recordtype_ss'] and doc['recordtype_ss'][0].to_s == 'lido'
  end

  def display_artists_field?(context, doc)
    doc['recordtype_ss'] and doc['recordtype_ss'][0].to_s == 'artists'
  end

  def display_objects_field?(context, doc)
    doc['recordtype_ss'] and (doc['recordtype_ss'][0].to_s == 'marc' or doc['recordtype_ss'][0].to_s == 'lido')
  end

  def display_marc_accessor_field?(context, doc)
    #NOTE: good diagnostic
    #puts "#{context.accessor} ****> #{doc.send(context.accessor)}"
    display_marc_field?(context, doc) and !context.accessor.nil? and !doc.send(context.accessor).nil?
  end

  def display_lido_accessor_field?(context, doc)
    #NOTE: good diagnostic
    #puts "#{context.accessor} ****> #{doc.send(context.accessor)}"
    display_lido_field?(context, doc) and !context.accessor.nil? and !doc.send(context.accessor).nil?
  end

  def render_related_content?(context,doc)
    return false if display_marc_field?(context, doc) == false
    return false if doc['resourceURL_ss'].nil?
    text_to_suppress = "View a digitized version"
    text_to_suppress2 = "View a selection of digital images in the Yale Center for British"
    links = []
    doc['resourceURL_ss'].each {  |item|
      text, url = item.split("\n")
      return false if text.start_with?(text_to_suppress)
      return false if text.start_with?(text_to_suppress2)
    }
    #NOTE: good diagnostic
    #puts "RELATED:#{doc['resourceURL_ss']}"
    #puts "CONTEXT:#{context.inspect}"
    true
  end

  def isLidoLoan?(context,doc)
    #puts context
    #puts doc
    if doc[:callnumber_ss] && doc[:callnumber_ss][0].start_with?("L") && display_lido_field?(context,doc)
      return true
    else
      return false
    end
  end
end
