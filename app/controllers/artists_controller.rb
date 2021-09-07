# frozen_string_literal: true

# Blacklight search controller for Collections
class ArtistsController < ApplicationController
  #include BlacklightMaps::ControllerOverride #ERJ from Georgia -https://gitlab.galileo.usg.edu/DLG/dlg/-/blob/master/app/controllers/collections_controller.rb
  include BlacklightRangeLimit::ControllerOverride
  include Blacklight::Catalog

  configure_blacklight do |config|

    config.search_builder_class = ArtistsSearch

    config.default_solr_params = {
        rows: 10
    }

    config.per_page = [15,50,100]

    config.add_facet_fields_to_solr_request!

    # Facets
    config.add_facet_field :beginDate_i,                label: I18n.t('blacklight.search.labels.begin_date'), limit: true
    config.add_facet_field :endDate_i,                label: I18n.t('blacklight.search.labels.end_date'), limit: true

    # Results Fields
    config.index.title_field = 'displayName_s'
    config.add_index_field :displayName_s,    label: I18n.t('blacklight.search.labels.display_name')
    config.add_index_field :nationality_s,   label: I18n.t('blacklight.search.labels.nationality')
    config.add_index_field :beginDate_i,    label: I18n.t('blacklight.search.labels.begin_date')
    config.add_index_field :endDate_i,    label: I18n.t('blacklight.search.labels.end_date')

    # Show Fields
    config.add_show_field :displayName_s,                  label: I18n.t('blacklight.search.labels.display_name')
    config.add_show_field :nationality_s,            label: I18n.t('blacklight.search.labels.nationality')
    config.add_show_field :beginDate_i,              label: I18n.t('blacklight.search.labels.begin_date')
    config.add_show_field :endDate_i,                        label: I18n.t('blacklight.search.labels.end_date')
    config.add_show_field :biography_s,               label: I18n.t('blacklight.search.labels.biography')
    config.add_show_field :remarks_s,                label: I18n.t('blacklight.search.labels.remarks')
    config.add_show_field :authorities_ss,                           label: I18n.t('blacklight.search.labels.authorities')

    config.show.html_title = 'displayName_s'

    config.add_sort_field 'displayName_s asc', label: I18n.t('blacklight.search.sort.artists')
    config.add_sort_field 'score desc, displayName_s asc', label: I18n.t('blacklight.search.sort.relevance')
    config.add_sort_field 'beginDate_i asc', label: I18n.t('blacklight.search.sort.begin_date_asc')
    config.add_sort_field 'beginDate_i desc', label: I18n.t('blacklight.search.sort.begin_date_desc')
    config.add_sort_field 'endDate_i asc', label: I18n.t('blacklight.search.sort.end_date_asc')
    config.add_sort_field 'endDate_i desc', label: I18n.t('blacklight.sort.end_date_desc')
    #config.add_sort_field 'created_at_dts desc', label: I18n.t('search.sort.newest')

#ERJ - some map config from https://gitlab.galileo.usg.edu/DLG/dlg/-/blob/master/app/controllers/collections_controller.rb
=begin
    config.add_facet_field 'geojson', label: '_', limit: -2, show: false
    config.view.maps.geojson_field = 'geojson'
    config.view.maps.placename_field = 'placename'
    config.view.maps.coordinates_field = 'coordinates'
    config.view.maps.search_mode = 'placename'
    config.view.maps.facet_mode = 'geojson'
    config.view.maps.initialview = '[[30.164126,-88.516846],[35.245619,-78.189697]]'
    config.view.maps.tileurl = 'http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
    config.view.maps.maxzoom = 12
    config.view.maps.show_initial_zoom = 10
    config.show.partials << :show_maplet
=end

    config.add_search_field 'all_fields', label: 'All Fields'


  end

end
