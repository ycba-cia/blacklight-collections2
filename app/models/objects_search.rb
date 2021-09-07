class ObjectsSearch < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  self.default_processor_chain += %i[
    limit_to_objects
  ]

  def limit_to_objects(solr_parameters)
    marc = "marc"
    lido = "lido"
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "recordtype_ss:#{marc} || recordtype_ss:#{lido}"
  end

end