# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument


  # self.unique_key = 'id'

  def physical_description
    self['physical_txt']
  end

  def publisher
    publisher = []
    value = self['publisher_ss']
    pub_date = self['publishDate_txt']
    publisher.push(value) unless value.nil? or value.empty?
    publisher.push(pub_date) unless value.nil? or value.empty? or pub_date.nil? or pub_date.empty?
    (value.nil? or value.empty?) ? nil : publisher.join(' ')
  end

  def orbis_link
    self['url_txt']
  end

  def callnumber
    self['callnumber_txt']
  end

  def note
    self['description_txt']
  end

  def cds_url
    cds_url = nil
    if self['url_ss'] and self['url_ss'][0].start_with?('http://hdl.handle.net/10079/bibid/')
      cds_url = self['url_ss'][0].gsub('http://hdl.handle.net/10079/bibid/', '')
    end
    cds_url
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
