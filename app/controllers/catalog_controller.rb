# frozen_string_literal: true
class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride

  include Blacklight::Catalog

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

  configure_blacklight do |config|
    config.view.gallery.partials = [:compact_index]
    config.view.masonry.partials = [:compact_index]
    #config.view.slideshow.partials = [:compact_index]

    config.index.thumbnail_method = :thumb
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

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
    config.per_page = [15,50,100]

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
    config.index.title_field = 'title_txt'
    config.index.display_type_field = 'recordtype_ss'

    # solr field configuration for document/show views
    config.show.title_field = 'title_txt'
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

    config.add_facet_field 'resource_facet', :label => 'Online Access'

    config.add_facet_field 'publishDate_ss', :label => 'Publication Year', single: true
    config.add_facet_field 'collection_facet', :label => 'Collection', :limit => 20
    config.add_facet_field 'language_facet', :label => 'Language', :limit => true
    config.add_facet_field 'lc_1letter_facet', :label => 'Call Number'
    #config.add_facet_field 'geographic_facet', :label => 'Region'
    config.add_facet_field 'author_ss', label: 'Creator'
    config.add_facet_field 'author_gender_ss', :label => 'Creator Gender'
    config.add_facet_field 'title_collective_ss', :label => 'Collective Title'
    config.add_facet_field 'era_facet', :label => 'Period'
    config.add_facet_field 'genre_name_facet', :label => 'Genre'
    config.add_facet_field 'object_name_ss', :label => 'Work Type'
    config.add_facet_field 'auth_format_ss', :label => 'Medium'
    config.add_facet_field 'topic_facet', :label => 'Subject Terms'
    config.add_facet_field 'geographic_facet', :label => 'Place Represented'
    config.add_facet_field 'topic_frameQuality_facet', :label => 'Frame Quality'
    config.add_facet_field 'topic_frameStyle_facet', :label => 'Frame Style'
    config.add_facet_field 'credit_line_facet', :label => 'Credit Line'


    config.add_facet_field 'earliestDate_i', :label => 'Earliest Date', :query => {
        a: { :label=> '0', :fq=> 'earliestDate_i:0'},
        b: { :label=> '1-1500', :fq=> 'earliestDate_i:[1 TO 1500]'},
        c: { :label=> '1501-1600', :fq=> 'earliestDate_i:[1501 TO 1600]'},
        d: { :label=> '1601-1700', :fq=> 'earliestDate_i:[1601 TO 1700]'},
        e: { :label=> '1701-1800', :fq=> 'earliestDate_i:[1701 TO 1800]'},
        f: { :label=> '1801-1900', :fq=> 'earliestDate_i:[1801 TO 1900]'},
        g: { :label=> '1901-2000', :fq=> 'earliestDate_i:[1901 TO 2000]'},
        h: { :label=> '2001-2100', :fq=> 'earliestDate_i:[2001 TO 2100]'},
        i: { :label=> 'unknown', :fq=> '-earliestDate_i:[* TO *]'}
    }#NEW_TO_BL
    config.add_facet_field 'latestDate_i', :label => 'Latest Date', :query => {
        a: { :label=> '0', :fq=> 'latestDate_i:0'},
        b: { :label=> '1-1500', :fq=> 'latestDate_i:[1 TO 1500]'},
        c: { :label=> '1501-1600', :fq=> 'latestDate_i:[1501 TO 1600]'},
        d: { :label=> '1601-1700', :fq=> 'latestDate_i:[1601 TO 1700]'},
        e: { :label=> '1701-1800', :fq=> 'latestDate_i:[1701 TO 1800]'},
        f: { :label=> '1801-1900', :fq=> 'latestDate_i:[1801 TO 1900]'},
        g: { :label=> '1901-2000', :fq=> 'latestDate_i:[1901 TO 2000]'},
        h: { :label=> '2001-2100', :fq=> 'latestDate_i:[2001 TO 2100]'},
        i: { :label=> 'unknown', :fq=> '-latestDate_i:[* TO *]'}
    }#NEW_TO_BL
    config.add_facet_field 'physical_heightValue_is', :label => 'Height [cm]', :query => {
        a: { :label=> '0', :fq=> 'physical_heightValue_is:0'},
        b: { :label=> '1-100', :fq=> 'physical_heightValue_is:[1 TO 100]'},
        c: { :label=> '101-200', :fq=> 'physical_heightValue_is:[101 TO 200]'},
        d: { :label=> '201-300', :fq=> 'physical_heightValue_is:[201 TO 300]'},
        e: { :label=> '301-400', :fq=> 'physical_heightValue_is:[301 TO 400]'},
        f: { :label=> '401-500', :fq=> 'physical_heightValue_is:[401 TO 500]'},
        g: { :label=> '501-600', :fq=> 'physical_heightValue_is:[501 TO 600]'},
        h: { :label=> '601-700', :fq=> 'physical_heightValue_is:[601 TO 700]'},
        i: { :label=> '701-800', :fq=> 'physical_heightValue_is:[701 TO 800]'},
        j: { :label=> 'unknown', :fq=> '-physical_heightValue_is[* TO *]'}
    }#NEW_TO_BL
    config.add_facet_field 'physical_widthValue_is', :label => 'Width [cm]', :query => {
        a: { :label=> '0', :fq=> 'physical_widthValue_is:0'},
        b: { :label=> '1-100', :fq=> 'physical_widthValue_is:[1 TO 100]'},
        c: { :label=> '101-200', :fq=> 'physical_widthValue_is:[101 TO 200]'},
        d: { :label=> '201-300', :fq=> 'physical_widthValue_is:[201 TO 300]'},
        e: { :label=> '301-400', :fq=> 'physical_widthValue_is:[301 TO 400]'},
        f: { :label=> '401-500', :fq=> 'physical_widthValue_is:[401 TO 500]'},
        g: { :label=> '501-600', :fq=> 'physical_widthValue_is:[501 TO 600]'},
        h: { :label=> '601-700', :fq=> 'physical_widthValue_is:[601 TO 700]'},
        i: { :label=> '701-800', :fq=> 'physical_widthValue_is:[701 TO 800]'},
        j: { :label=> 'unknown', :fq=> '-physical_widthValue_is[* TO *]'}
    }#NEW_TO_BL

    
#range limit gem buggy, using above query distribution instead https://github.com/projectblacklight/blacklight_range_limit
=begin
    config.add_facet_field 'earliestDate_i',
                           label: 'Earliest Date', limit: 3,
                           range: { segments: false }, segments: false
    config.add_facet_field 'latestDate_i',
                           label: 'Latest Date', limit: 3,
                           range: { segments: false }, segments: false
    config.add_facet_field 'physical_heightValue_is',
                           label: 'Height [cm]', limit: 3,
                           range: { segments: false }, segments: false
    config.add_facet_field 'physical_widthValue_is',
                           label: 'Width [cm]', limit: 3,
                           range: { segments: false }, segments: false
=end

    config.add_facet_field 'author_additional_ss', label: 'Contributor', show: false
    config.add_facet_field 'topic_subjectActor_ss', label: 'People Represented or Subject', show: false
    config.add_facet_field 'form_genre_ss', label: 'Form Genre', show: false

    #config.add_facet_field 'example_pivot_field', label: 'Pivot Field', :pivot => ['format', 'language_facet']

    # config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
    #    :years_5 => { label: 'within 5 Years', fq: "pub_date:[#{Time.zone.now.year - 5 } TO *]" },
    #    :years_10 => { label: 'within 10 Years', fq: "pub_date:[#{Time.zone.now.year - 10 } TO *]" },
    #    :years_25 => { label: 'within 25 Years', fq: "pub_date:[#{Time.zone.now.year - 25 } TO *]" }
    # }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!



    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # config.add_index_field 'title_t', :label => 'Title'
    #config.add_index_field 'type_txt', :label => 'Type'
    config.add_index_field 'auth_author_display_txt', :label => 'Creator'
    config.add_index_field 'publishDate_txt', label: "Date"
    config.add_index_field 'format_txt', :label => 'Medium'
    config.add_index_field 'collection_txt', :label => 'Collection'
    config.add_index_field 'credit_line_txt', :label => 'Credit Line'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    #config.add_show_field 'title_t', :label => 'Title'

    break_separator = {words_connector: ' <br/> ', last_word_connector: ' <br/> ', two_words_connector: ' <br/> '}
    config.add_show_field 'author_ss', :label => 'Creator', link_to_search: true, separator_options: break_separator
    config.add_show_field 'author_additional_ss', :label => 'Contributors', link_to_search: true, separator_options: break_separator
    config.add_show_field 'title_alt_txt', :label => 'Alternate Title(s)', separator_options: break_separator
    config.add_show_field 'publishDate_txt', :label => 'Date', unless:  :display_marc_field?
    config.add_show_field 'format_txt', :label => 'Medium'
    config.add_show_field 'physical_txt',  :label => 'Dimensions', unless:  :display_marc_field?
    config.add_show_field 'type_ss', :label => 'Classification' #Bibliographic
    config.add_show_field 'publisher_ss', accessor: 'publisher', :label => 'Imprint', if: :display_marc_accessor_field? #Bibliographic
    config.add_show_field 'physical_description', accessor: 'physical_description', label: 'Physical Description', if: :display_marc_accessor_field? #NOT_IN_VU
    config.add_show_field 'edition_ss', label: 'Edition' #Bibliographic
    config.add_show_field 'orbis_link', accessor: 'orbis_link', :label => 'Full Orbis Record', helper_method: 'render_as_link', if: :display_marc_accessor_field? #NOT_IN_VU
    config.add_show_field 'resourceURL_ss', :label => 'Related content', helper_method: 'render_related_content', if: :display_marc_field? #NOT_IN_VU
    config.add_show_field 'description_txt', :label => 'Inscription(s)/Marks/Lettering', helper_method: 'render_citation', unless:  :display_marc_field?
    config.add_show_field 'note', accessor: 'note', :label => 'Notes', helper_method: 'render_citation', if: :display_marc_accessor_field? #NOT_IN_VU
    config.add_show_field 'marc_contents_txt', label: 'Contents' #Bibliographic #NOT_IN_VU
    config.add_show_field 'credit_line_txt', :label => 'Credit Line'
    config.add_show_field 'isbn_ss', :label => 'ISBN' #NOT_IN_VU
    config.add_show_field 'callnumber_txt', :label => 'Accession Number', unless: :display_marc_field?
    config.add_show_field 'callnumber', accessor: 'callnumber', :label => 'Call Number', if: :display_marc_accessor_field? #NOT_IN_VU
    config.add_show_field 'collection_txt', :label => 'Collection'
    config.add_show_field 'curatorial_comment_txt', :label => 'Curatorial Comment', helper_method: 'combine_curatorial_comments' #NEW_TO_BL
    config.add_show_field 'geographic_culture_txt', :label => 'Culture' #NOT_IN_VU
    config.add_show_field 'era_txt', :label => 'Era' #NOT_IN_VU
    config.add_show_field 'url_txt', :label => 'Link', helper_method: 'render_as_link', unless:  :display_marc_field?
    config.add_show_field 'topic_subjectActor_ss', :label => 'People Represented or Subject', link_to_search: true, separator_options: break_separator
    config.add_show_field 'topic_ss', :label => 'Subject Terms - Current', link_to_search: 'topic_facet', separator_options: break_separator

    config.add_show_field 'topic_frameCrossSection_ss', :label => 'Cross-section', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameOrnament_ss', :label => 'Ornaments', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameFeature_ss', :label => 'Features', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameAlteration_ss', :label => 'Alteration', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameStatus_ss', :label => 'Status', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameQuality_ss', :label => 'Quality', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameStyle_ss', :label => 'Style', link_to_search: true, separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_frameSubjectConcept_ss', :label => 'Subject Terms', helper_method: 'combine_topic_subject', separator_options: break_separator #NEW_TO_BL
    config.add_show_field 'topic_subjectPlace', :label => 'Place Represented', link_to_search: true, separator_options: break_separator #NEW_TO_BL


    config.add_show_field 'geographic_facet', label: 'Place Represented', link_to_search: true, separator_options: break_separator
    config.add_show_field 'form_genre_ss', :label => 'Form Genre', link_to_search: true, separator_options: break_separator  #Bibliographic #NOT_IN_VU
    config.add_show_field 'citation_txt', :label => 'Publications', helper_method: 'render_citation'
    config.add_show_field 'videoURL_ss', :label => 'Related Video', helper_method: 'render_as_link'

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

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = {
        qf: '$author_qf',
        pf: '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
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

  def display_marc_accessor_field?(context, doc)
    puts "#{context.accessor} ****> #{doc.send(context.accessor)}"
    display_marc_field?(context, doc) and !doc.send(context.accessor).nil?
  end
end
