#module Blacklight::Solr::Citations
module Citations #ruby3 use module Citations rather than Blacklight::Solr::Citations
  extend ActiveSupport::Concern

  #note: rough ruby version of vufind php code from:
  #bac6-dev:/usr/local/vufind-prod/vufind-1.2/web/sys/CitationBuilder.php
  def authors
    a = (self['author_ss'] ? self['author_ss'] : [""]) + (self['author_additional_ss'] ? self['author_additional_ss'] : [""])
    if a.length > 1
      a.delete("")
    end
    a
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
    a2 = ""
    authors.each_with_index do |a,i|
      a = abbreviateName(a)
      if i+1 == authors.length && i > 0
        a2 << "& " << stripPunctuation(a) << "."
      elsif authors.length > 1
        a2 << stripPunctuation(a) << ", "
      else
        a2 << stripPunctuation(a) << "."
      end
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

  def getAPA
    apafields = Hash.new
    apafields["title"] = getAPATitle + "."
    apafields["authors"] = getAPAAuthors
    apafields["publisher"] = getPublisher
    apafields["year"] = "(" + getYear + ")."
    apafields["edition"] = getEdition
    return apafields
  end

  def getMLA
    apafields = Hash.new
    apafields["title"] = getMLATitle + "."
    apafields["authors"] = getMLAAuthors
    apafields["publisher"] = getPublisher
    apafields["year"] = getYear + "."
    apafields["edition"] = getEdition
    return apafields
  end

  def getMLATitle
    capitalizeTitle(title[0])
  end

  def getMLAAuthors
    return "" if authors[0] == ""
    if authors.length > 4
      return cleanNameDates(authors[0]) + ", et al"
    end
    newauthors = ""
    authors.each_with_index do |author, i|
      if i+1 == authors.length && i > 0
        #last
        newauthors = newauthors + ", and " + reverseName(stripPunctuation(author)) << "."
      elsif authors.length > 1 && i != 0
        newauthors = newauthors + ", " + reverseName(stripPunctuation(author))
      elsif authors.length > 1 && i == 0
        newauthors = reverseName(stripPunctuation(author))
      else
        #first
        newauthors = cleanNameDates(author) << "."
      end
    end
      return newauthors
    end
#

  def reverseName n
    return "" if n[0].nil?
    return "" if n[0] == ""
    parts = n.split(",").each(&:strip!)
    if parts[1].nil? || isDateRange?(parts[1])
      return parts[0]
    end
    name = parts[1] + " " + parts[0]
    if parts[2].nil? == false && isNameSuffix?(parts[2])
      name = name + ", " + parts[2]
    end
    return name
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

  def capitalizeTitle s
    exceptions = ['a', 'an', 'the', 'against', 'between', 'in', 'of',
                  'to', 'and', 'but', 'for', 'nor', 'or', 'so', 'yet', 'to']
    words = s.split(" ")
    newwords = Array.new
    followsColon = false
    words.each { |word|
      if !(exceptions.include? word) || followsColon
        word = word.capitalize
      end
      followsColon = false
      newwords.push(word)
      followsColon = true if word[word.length - 1] == ":"
    }
      return newwords.join(" ")
  end

  def cleanNameDates n
    parts = n.split(",").each(&:strip!)
    name = ""
    return name if parts[0].nil?
    name = parts[0]
    return name if parts[1].nil?
    if isDateRange?(parts[1])
      return name
    else
      name = name + ", " + parts[1]
    end
    return name if parts[2].nil?
    if isNameSuffix?(parts[2])
      name = name + ", " + parts[2]
    end
    return name
  end

  def isNameSuffix? n
    return false if n.nil?
    return false if n == ""
    n = stripPunctuation(n)
    suffix = ["Jr","Sr"] #MD? pHD?
    return true if suffix.include? n
    return true if (/^[MDCLXVI]+$/ =~ n) == 0
    return false
  end
end