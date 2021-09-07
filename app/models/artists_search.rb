class ArtistsSearch < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  self.default_processor_chain += %i[
    limit_to_artists
  ]

  def limit_to_artists(solr_parameters)
    artists = "artists"
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "recordtype_ss:#{artists}"
    solr_parameters
  end

end