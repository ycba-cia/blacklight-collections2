module Blacklight::Solr::Citations
  extend ActiveSupport::Concern

  def authors
    (self['author_ss'] ? self['author_ss'] : [""]) + (self['author_additional_ss'] ? self['author_additional_ss'] : [""])
  end

  def title
    self['title_short_ss'] ? self['title_short_ss'] : [""]
  end

  def publisher_cit
    self['publisher_ss'] ? self['publisher_ss'] : [""]
  end

  def publishDate
    self['publishDate_ss'] ? self['publishDate_ss'] : [""]
  end

  def edition
    self['edition_ss'] ? self['edition_ss'] : [""]
  end


  #shouldn't exist for test of empty
  def pubPlace
    self['pubplace_ss'] ? self['pubplace_ss'] : [""]
  end

  def getAPATitle
    stripPunctuation(title[0])
  end

  #TODO start here
  def getAPAAuthors
    return "" if authors[0] == ""
    i = 0
    a2 = ""
    authors.each do |a|
      a = abbreviateName(a)
      if i+1 == authors.length && i > 0
        a2 << "& " << stripPunctuation(a) << "."
      elsif authors.length > 1
        a2 << stripPunctuation(a) << ", "
      else
        a2 << stripPunctuation(a) << "."
      end
      i=i+1
    end
    a2
  end

  def getPublisher
    publisher_cit[0]
  end

  def getYear
    publishDate[0]
  end

  def getEdition
    return "" if edition[0].empty?
    return "" if edition[0] == "1st ed."
    if isPunctuated(edition[0])
      return edition[0]
    else
      return edition[0] + "."
    end
  end

  def stripPunctuation s
    return "" if s == ""
    return "" if s.nil?
    s = s.gsub(/[.,:;\/]/,"").strip
    s
  end

  def isPunctuated s
    return false if s == ""
    p = [".","?","!"]
    p.include? s[s.length-1]
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