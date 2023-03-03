# frozen_string_literal: true
require "citations"
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument
  include Blacklight::Solr::Citations


  # self.unique_key = 'id'

  def physical_description
    self['physical_txt']
  end

  def publisher
    publisher = []
    value = self['publisher_ss']
    pub_date = self['publishDate_txt']
    publisher.push(value) unless value.nil? or value.empty?
    publisher.push(pub_date) unless value.nil? or value.empty? or pub_date.nil? or pub_date.empty? or value[0].include?(pub_date[0])
    (value.nil? or value.empty?) ? nil : publisher.join(' ')
  end

  def orbis_link_acc
    self['url_ss']
  end

  def callnumber_acc
    self['callnumber_ss']
  end

  def note_acc
    self['description_ss']
  end

  def cds_url
    cds_url = nil
    if self['url_ss'] and self['url_ss'][0].start_with?('http://hdl.handle.net/10079/bibid/')
      cds_url = self['url_ss'][0].gsub('http://hdl.handle.net/10079/bibid/', '')
    end
    cds_url
  end

  def cite_as
    return "Yale Center for British Art" unless self['citation_ss']
  end

  # new accessor fields, so as to render ordering differently for marc and lido, also using legacy methods above here as accessors too
  def title_acc
    self['title_ss']
  end

  def author_acc
    self['author_ss']
  end

  def physical_acc
    self['physical_ss']
  end

  def collection_acc
    self['collection_ss']
  end

  def credit_line_acc
    self['credit_line_ss']
  end

  def type_acc
    self['type_ss']
  end

  def topic_acc
    self['topic_ss']
  end

  def exhibition_history_acc
    self['exhibition_history_ss']
  end

  def dummy_ort_marc_acc
    self['id']
  end

  def dummy_ort_lido_acc
    self['id']
  end

  def detailed_onview_acc
    self['detailed_onview_ss']
  end

  def titles_primary_acc
    self['titles_primary_ss']
  end

  def titles_former_acc
    self['titles_former_ss']
  end

  def titles_additional_acc
    self['titles_additional_ss']
  end
  def loc_naf_author_acc
    self['loc_naf_author_ss']
  end
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
end
