module Blacklight::Solr::Citations
  extend ActiveSupport::Concern

  def author
    self['author_ss'] + self['author_additional_ss']
  end

  def title
    self['title_short_ss']
  end
end