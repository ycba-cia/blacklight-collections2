module Blacklight::Solr::Citations
  extend ActiveSupport::Concern

  def authors
    self['author_ss'] + self['author_additional_ss']
  end

  def title
    self['title_short_ss']
  end

  def publisher_cit
    self['publisher_ss']
  end

  def publishDate
    self['publishDate_ss']
  end

  def edition
    self['edition_ss']
  end

  def getAPATitle
    stripPunctuation(title)
  end

  #TODO start here
  def getAPAAuthors
    i = 0
    a2 = ""
    authors.each do |a|
      a = abbreviateName(a)
      if i+1 == authors.length && i > 0
        a2 << " & " << stripPunctuation(a) << "."
      elsif authors.length > 1
        a2 << stripPunctuation(a) << ", "
      else
        a2 << stripPunctuation(s) << "."
      end
      i=i+1
    end
    a2
  end

  def getPublisher

  end

  def getYear

  end

  def getEdition

  end

  def stripPunctuation s
    s = s.gsub(/[.,:;\/]/,"").strip!
    s
  end

  def abbreviateName n
    parts = n.split(",").each(&:strip!)
    name = parts[0]
    if (parts[1].nil?)==false && !isDateRange?(parts[1].strip)
      fnameParts = parts[1].split(" ").each(&:strip!)
      fname_initials = fnameParts.map { |f| f[0] + "."}
    end
    if fname_initials.nil? == true
      return name
    else
      return name = name +", "+ fname_initials.join(" ")
    end
  end

  def isDateRange?(s)
    s.strip!
    m = /^\d{4}.\d{4}?$/ =~ s
    if m.nil?
      return false
    else
      return true
    end
  end
end