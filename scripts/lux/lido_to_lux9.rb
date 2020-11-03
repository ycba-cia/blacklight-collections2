require 'rexml/document'
require 'json'
require 'yaml'
require 'mysql2'
require 'open-uri'
require 'active_support/inflector'
require 'logger'

#validation method
# /Users/ermadmix/Documents/github_clones/json-schema-validation/ruby run_validation.rb 80

#synch method
#aws s3 --profile spinup-0010d8-ycba-records sync /app/blacklight-collections2/scripts/lux/output s3://spinup-0010d8-ycba-records

#logging
@log = Logger.new('lux.log')
@log.level = Logger::INFO

#CONFIG
rails_root = "/Users/ermadmix/Documents/RubymineProjects/blacklight-collections2"
#rails_root = "/app/blacklight-collections2"
y = YAML.load_file("#{rails_root}/config/local_env.yml")
oai_hostname = "oaipmh-prod.ctsmybupmova.us-east-1.rds.amazonaws.com"
oai_username = "oaipmhuser"
oai_password = y["oaipmh-prod"]
oai_databasename = "oaipmh"
sslca = "#{rails_root}/#{y['awscert']}"
#puts "PW:#{oai_password}"
puts "SSLCA:#{sslca}"
@oai_client = Mysql2::Client.new(:host=>oai_hostname,:username=>oai_username,:password=>oai_password,:database=>oai_databasename,:sslca=>sslca)
puts "oaipmh ping:#{@oai_client.ping}"
#TODO: configure the streaming query in the driver

#METHODS
def map_supertype2(classification)
  case classification
  when "Brass Rubbing"
    s2 = "Prints"
  when "Ceramic"
    s2 = "Decorative Arts"
  when "Drawing & Watercolor"
    s2 = "Drawings"
  when "Drawing & Watercolor-Architectural"
    s2 = "Drawings"
  when "Drawing & Watercolor-Miniature"
    s2 = "Drawings"
  when "Drawing & Watercolor-Sketchbook"
    s2 = "Drawings"
  when "Frame"
    s2 = "Decorative Arts"
  when "Manuscript"
    s2 = "Manuscripts"
  when "Model"
    s2 = "Models"
  when "Paint Box"
    s2 = "Tools and Equipment"
  when "Painted Object"
    s2 = "Tools and Equipment"
  when "Painting"
    s2 = "Paintings"
  when "Photograph"
    s2 = "Photographs"
  when "Poster"
    s2 = "Prints"
  when "Print"
    s2 = "Prints"
  when "Print-printing-plate"
    s2 = "Tools and Equipment"
  when "Rare Book"
    s2 = "Books"
  when "Sculpture"
    s2 = "Sculptures"
  when "Silver"
    s2 = "Decorative Arts"
  when "Wedgwood"
    s2 = "Sculptures"
  else
    s2 = ""
  end
  s2
end
def map_supertype1(supertype2)
  case supertype2
  when "Prints"
    s1 = "Two-Dimensional Objects"
  when "Decorative Arts"
    s1 = "Three-Dimensional Objects"
  when "Drawings"
    s1 = "Two-Dimensional Objects"
  when "Manuscripts"
    s1 = "Archival and Manuscript Material"
  when "Models"
    s1 = "Three-Dimensional Objects"
  when "Tools and Equipment"
    s1 = "Three-Dimensional Objects"
  when "Paintings"
    s1 = "Two-Dimensional Objects"
  when "Photographs"
    s1 = "Two-Dimensional Objects"
  when "Books"
    s1 = "Text"
  when "Sculptures"
    s1 = "Three-Dimensional Objects"
  else
    s1 = ""
  end
  s1
end

def get_images(id)
  url = "https://deliver.odai.yale.edu/info/repository/YCBA/object/#{id.gsub("tms:","")}/type/2"
  #puts url
  json = open(url).read
  j = JSON.parse(json)
  i = 0
  images = Array.new
  manifests = Array.new
  captions = Array.new
  has_manifest = false
  while true
    image = j["#{i}"]
    break if image.nil?
    best_image = image.dig("derivatives","3","url") || image.dig("derivatives","2","url") || image.dig("derivatives","1","url")
    has_manifest = true if image.dig("derivatives","7","url")
    images.push(best_image) unless best_image.nil?
    caption = image.dig("metadata","caption") || ""
    captions.push(caption)
    i += 1
  end
  manifests.push(url)
  manifests.push("https://manifests.britishart.yale.edu/manifest/#{id.gsub("tms:","")}") if has_manifest
  return images,manifests,captions
end
def get_collection(s)
  c = ""
  c = "Frames (YCBA)" if s == "ycba:frames"
  c = "Prints and Drawings (YCBA)" if s == "ycba:pd"
  c = "Paintings and Sculpture (YCBA)" if s == "ycba:ps"
  c
end
def get_access_contact
  "ycbaonline@yale.edu"
end
def get_date_role_authority(s)
  a = ""
  a = "http://vocab.getty.edu/page/aat/300435447" if s == "created"
  [a]
end
def get_agent_type_authority(s)
  a = ""
  a = "http://vocab.getty.edu/page/aat/300024979" if s == "person"
  a = "http://vocab.getty.edu/page/aat/300025969" if s == "corporation"
  a
end
def get_place_role(s)
  a = ""
  a = "depicted or about" if s == "subjectPlace"
  a
end
def get_measurement_type_authority(s)
  a = ""
  a = "http://vocab.getty.edu/page/aat/300055647" if s == "width"
  a = "http://vocab.getty.edu/page/aat/300055644" if s == "height"
  a = "http://vocab.getty.edu/page/aat/300072633" if s == "depth"
  a
end
def get_measurement_authority(s)
  a = ""
  a = "http://id.loc.gov/authorities/subjects/sh2008006746" if s == "cm"
  a
end
def normalize_aat(s)
  s = "30000000" + s if s.length == 1
  s = "3000000" + s if s.length == 2
  s = "300000" + s if s.length == 3
  s = "30000" + s if s.length == 4
  s = "3000" + s if s.length == 5
  s = "300" + s if s.length == 6
  s = "30" + s if s.length == 7
  s = "3" + s if s.length == 8
  "http://vocab.getty.edu/page/aat/#{s}"
end
#note changes underlying string
def cap_first_letter(s)
  s[0] = s[0].upcase
  s
end
def wktize(s)
  a = Array.new
  s.each do |x|
    a.push("POINT (#{x.gsub(", "," ").gsub(","," ")})")
  end
  a
end
def wkttype(s)
  a = Array.new
  s.each do |x|
    a.push("point")
  end
  a
end
def get_citation_type(s)
  s = "publication" if s == "publication event"
  s
end
def create_json(id,xml_str,set_spec)
  filename = "testrecords/lido_#{id}_public.xml"
  #file = File.new(filename)
  #xml = REXML::Document.new(file)
  xml = REXML::Document.new(xml_str)
  solrjson = Hash.new

  xml_root = xml.root
  if xml_root.nil? || xml_root.elements['lido:descriptiveMetadata'].nil?
    puts "NO RECORD FOR:#{id}"
    return
  end
  xml_desc = xml_root.elements['lido:descriptiveMetadata']

  a = Array.new
  a2 = Array.new #identifiers
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:workID[@lido:type="inventory number"]') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }

  h = Hash.new
  h["identifier_value"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_display"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_type"] = "accession number"
  h["identifier_label"] = "Accession Number"
  a2.push(h) if h.length > 0

  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }

  h = Hash.new
  h["metadata_arrived_in_LUX "] = Time.now.utc.iso8601 #json generation
  h["metadata_rights_label"] = "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication"
  h["metadata_rights_URI"] = ["https://creativecommons.org/publicdomain/zero/1.0/"]
  h["metadata_identifier"] = "ycba-#{a[0]}"
  solrjson["record"] = h

  blacklight_id = "tms:#{a[0]}" #for access_in_repository_URI
  h = Hash.new
  h["identifier_value"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_display"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_type"] = "system"
  h["identifier_label"] = "System"
  a2.push(h) if h.length > 0
  h = Hash.new
  h["identifier_value"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_display"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_type"] = "TMS object identifier"
  h["identifier_label"] = "TMS Object Identifier"
  a2.push(h)
  h = Hash.new
  h["identifier_value"] = "tms:#{a[0]}" if a.length > 0 #not-multivalued
  h["identifier_display"] = "tms:#{a[0]}" if a.length > 0 #not-multivalued
  h["identifier_type"] = "YCBA blacklight identifier"
  h["identifier_label"] = "YCBA Blacklight Identifier"
  a2.push(h)
  solrjson["identifiers"] = a2 if a2.length > 0

  h = Hash.new
  a = Array.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  a2 = Array.new
  a.each do |x|
    level2 = map_supertype2(x)
    level1 = map_supertype1(level2)
    if level1 == "Archival and Manuscript Material"
      a2.push([level1])
    else
      a2.push([level1,level2])
    end
  end
  h["supertypes"] = (a2.length > 0 ? a2 : [""])

  a1 = Array.new
  a2 = Array.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:objectWorkTypeWrap/lido:objectWorkType[lido:conceptID/@lido:type="Object name"]') { |x|

    x.elements.each('lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }

    x.elements.each('lido:conceptID[@lido:source="AAT"]') { |x2|
      #puts "url:#{x2.text}"
      unless x2.text.nil?
        s = x2.text.strip
        a2.push(normalize_aat(s))
      end
    }

  }
  h["specific_type"] = a1 if a1.length > 0
  h["specific_type_URI"] = a2 if a2.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:displayStateEditionWrap/displayState|displayEdition') { |x|
    #a.push(x.text.strip) unless x.text.nil?
    unless x.text.nil?
      h2 = Hash.new
      h2["value"] = x.text.strip
      a.push(h2);
    end
  }
  h["edition_display"] = a if a.length > 0

  a = Array.new
  test = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventActor') { |x|
    x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:pref="preferred"]') { |x2|
      a.push(x2.text.strip) unless x2.text.nil?
    }
    x.elements.each('lido:actorInRole/lido:roleActor/lido:term[../lido:conceptID[@lido:type="Object related role"]]') { |x2|
      test = x2.text.strip unless x2.text.nil?
    }
  }
  if a.length > 0 && test=="publisher"
    a2 = Array.new
    h2 = Hash.new
    h2["value"] = a[0]
    a2.push(h2)
    h["imprint_display"] = a2
  end

  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventMaterialsTech/lido:materialsTech/lido:termMaterialsTech/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  h["materials_display"] = (a.length > 0 ? a : [""])

  h["provenance_display"] = [""]

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet[lido:rightsType/lido:conceptID/@lido:label="object ownership"]/lido:creditLine') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["acquisition_source_display"] = s.length > 0 ? [s] : [""]

  solrjson["basic_descriptors"] = h
  puts solrjson["basic_descriptors"]

  a = Array.new
  cits = Array.new
  i = 0
  xml_desc.elements.each('lido:eventWrap/lido:eventSet') { |x|
    #i = i + 1

    a1 = Array.new
    x.elements.each('lido:event/lido:eventType/lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    next if a1.length > 0 && a1[0] == "Curatorial comment"

    a11 = Array.new
    x.elements.each('lido:event/lido:eventName/lido:appellationValue') { |x2|
      a11.push(x2.text.strip) unless x2.text.nil?
    }
    a11.each_with_index { |x2,ii|
      h = Hash.new
      h["citation_string_display"] = x2.gsub("^","")
      h["citation_identifier_type"] = ""
      h["citation_URI"] = [""]
      h["citation_type"] = get_citation_type(a1[ii])
      cits.push(h)
    }

    #a2 = Array.new #removed to flatten
    x.elements.each('lido:event/lido:eventActor') { |x2|
      a3 = Array.new
      x2.elements.each('lido:displayActorInRole') { |x3|
        a3.push(x3.text.strip) unless x3.text.nil?
      }
      a4 = Array.new
      x2.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:label="Alpha Sort"]') { |x3|
        a4.push(x3.text.strip) unless x3.text.nil?
      }
      a5 = Array.new
      x2.elements.each('lido:actorInRole/lido:actor/lido:actorID[@lido:type="url"]') { |x3|
        a5.push(x3.text.strip) unless x3.text.nil?
      }
      a6 = Array.new
      x2.elements.each('lido:actorInRole/lido:roleActor') { |x3|
        x3.elements.each('lido:conceptID') { |x4|
          group = a1[0]
          type = x4.attributes["lido:type"]
          source = x4.attributes["lido:source"]
          label = x4.attributes["lido:label"]
          x3.elements.each('lido:term') { |x4|
            unless x4.text.nil?
              a6.push(x4.text.strip) if group=="production" && type=="Object related role" && source=="AAT"
              a6.push(x4.text.strip) if group=="exhibition" && label=="exhibition related constituent role" && source=="AAT"
              a6.push(x4.text.strip) if group=="publication event" && type=="Publication related role" && source=="AAT"
              a6.push(x4.text.strip) if group=="acquisition" && label=="Acquisition related role" && source=="AAT"
            end
          }
        }
      }
      a7 = Array.new
      a9 = Array.new
      x2.elements.each('lido:actorInRole/lido:roleActor/lido:conceptID') { |x3|
        #puts "X2:#{x2.text.nil?}"
        group = a1[0]
        type = x3.attributes["lido:type"]
        source = x3.attributes["lido:source"]
        label = x3.attributes["lido:label"]
        #puts "group #{group}"
        #puts "type: #{type}"
        #puts "source: #{source}"
        #puts "label: #{label}"
        unless x3.text.nil?
          aat_uri = normalize_aat(x3.text.strip)
          a7.push(aat_uri) if group=="production" && type=="Object related role" && source=="AAT"
          a7.push(aat_uri) if group=="exhibition" && label=="exhibition related constituent role" && source=="AAT"
          a7.push(aat_uri) if group=="publication event" && type=="Publication related role" && source=="AAT"
          a7.push(aat_uri) if group=="acquisition" && label=="Acquisition related role" && source=="AAT"
        end
      }
      a8 = Array.new
      a10 = Array.new
      x2.elements.each('lido:actorInRole/lido:actor') { |x3|
        unless x3.nil? && x3.attributes["lido:type"].nil?
          a8.push(x3.attributes["lido:type"])
        end
        unless x3.nil?
          x3.elements.each('lido:nationalityActor/lido:term') { |x4|
            a10.push(x4.text.strip) unless x4.text.nil?
          }
        end
      }
      group = (a1.length > 0 ? a1[0].split.map(&:capitalize).join(' ') : "Event")
      role = (a6.length > 0 ? a6[0].split.map(&:capitalize).join(' ') : "Agent")
      name = (a3.length > 0 ? a3[0] : "Unidentified Agent")
      #v8 -deprecated group -- role -- name
      #puts "G:#{group}"
      #puts "R:#{role}"
      #puts "D:#{name}"
      #a9.push(group+" -- "+role+" -- "+name)
      a9.push(name)
      h = Hash.new
      i = i + 1
      #h["agent_display"] = (a3.length > 0 ? a3[0] : "") #replaced by 3-tuple
      h["agent_display"] = (a9.length > 0 ? a9[0] : "") #3-tuple a9
      h["agent_sortname"] = (a4.length > 0 ? a4[0] : "")
      h["agent_URI"] = (a5.length > 0 ? a5 : [""])
      h["agent_role_label"] = (a6.length > 0 ? a6[0] : "")
      h["agent_role_code"] = ""
      h["agent_role_URI"] = (a7.length > 0 ? a7 : [""])
      h["agent_type_display"] = (a8.length > 0 ? a8[0] : "")
      h["agent_culture_display"]= (a10.length > 0 ? a10 : [""])
      h["agent_type_URI"] = (a8.length > 0 ? [get_agent_type_authority(a8[0])] : [""])
      h["agent_sort"] = (a3.length > 0 ? "#{i.to_s}" : "")
      h["agent_context_display"] = [group]
      #a2.push(h) if h.length > 0
      a.push(h) if h.length > 0
    }
    #a.push(a2) if a2.length > 0
  }
  if a.length == 0
    h = Hash.new
    h["agent_display"] = ""
    h["agent_sortname"] = ""
    h["agent_URI"] = [""]
    h["agent_role_label"] = ""
    h["agent_role_code"] = ""
    h["agent_role_URI"] = [""]
    h["agent_type_display"] = ""
    h["agent_type_URI"] = [""]
    h["agent_culture_display"] = [""]
    h["agent_sort"] = ""
    h["agent_context_display"] = [""]
    #a.push([h])
    a.push(h)
  end
  a_sorted = a.sort_by { |k| k["agent_display"].start_with?("Production") ? "AA#{k["agent_display"]}" : k["agent_display"] }
  a_sorted2 = a_sorted.each_with_index { |k,i| k["agent_sort"] = (i+1).to_s }
  solrjson["agents"] = a_sorted2

  if cits.length == 0
    h = Hash.new
    h["citation_string_display"] = ""
    h["citation_identifier_type"] = ""
    h["citation_URI"] = [""]
    h["citation_type"] = ""
    cits.push(h)
  end
  solrjson["citations"] = cits

  a = Array.new
  a1 = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet[@lido:type="Repository title"]/lido:appellationValue[@lido:pref="preferred"]') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["title_display"] = a1[0] if a1.length > 0
  h["title_type"] = "primary" if a1.length > 0
  h["title_label"] = "Primary" if a1.length > 0
  a.push(h) if h.length > 0
  a1 = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet/lido:appellationValue[@lido:pref="alternate"]') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["title_display"] = a1[0] if a1.length > 0
  h["title_type"] = "alternate" if a1.length > 0
  h["title_label"] = "Alternate" if a1.length > 0
  a.push(h) if h.length > 0
  if a.length == 0
    h = Hash.new
    h["title_display"] = ""
    h["title_type"] = ""
    h["title_label"] = ""
    a.push(h)
  end
  solrjson["titles"] = a

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:objectMeasurementsWrap/lido:objectMeasurementsSet') { |x|

    s = String.new
    x.elements.each('lido:displayObjectMeasurements') { |x2|
      s =  x2.text.strip unless x2.text.nil?
    }

    s5 = String.new
    x.elements.each('lido:objectMeasurements/lido:extentMeasurements') { |x2|
      s5 =  x2.text.strip unless x2.text.nil?
    }

    x.elements.each('lido:objectMeasurements/lido:measurementsSet') { |x2|
      s2 = String.new
      x2.elements.each('lido:measurementType') { |x3|
        s2 = x3.text.strip unless x3.text.nil?
      }

      s3 = String.new
      x2.elements.each('lido:measurementUnit') { |x3|
        s3 = x3.text.strip unless x3.text.nil?
      }

      s4 = String.new
      x2.elements.each('lido:measurementValue') { |x3|
        s4 = x3.text.strip unless x3.text.nil?
      }
      h = Hash.new
      h["measurement_element"] = (s5.length > 0 ? s5 : "")
      h["measurement_label"] = "Dimensions"
      h["measurement_display"] = (s.length > 0 ? s : "")
      h["measurement_type"] = (s2.length > 0 ? s2 : "")
      h["measurement_type_URI"] = (s2.length > 0 ? [get_measurement_type_authority(s2)] : [""])
      h["measurement_unit"] = (s3.length > 0 ? s3 : "")
      h["measurement_unit_URI"] = (s3.length > 0 ? [get_measurement_authority(s3)] : [""])
      h["measurement_value"] = (s4.length > 0 ? s4 : "")
      a.push(h)
    }

  }
  if a.length == 0
    h = Hash.new
    h["measurement_element"]  = ""
    h["measurement_label"] = ""
    h["measurement_display"] = ""
    h["measurement_type"] = ""
    h["measurement_type_URI"] = [""]
    h["measurement_unit"] = ""
    h["measurement_unit_URI"] = [""]
    h["measurement_value"] = ""
    a.push(h)
  end
  solrjson["measurements"] = a

#v7 not nesting in this way
=begin
  if a.length == 0
    h2 = Hash.new
    h2["measurement_display"] = ""
    h = Hash.new
    h["measurement_type"] = ""
    h["measurement_type_URI"] = [""]
    h["measurement_unit"] = ""
    h["measurement_unit_URI"] = [""]
    h["measurement_value"] = ""
    h2["measurements"] = [h]
    a.push(h2)
  end
  solrjson["measurements"] = a
=end

  a = Array.new
  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:displayEvent[../lido:event/lido:eventType/lido:term="Curatorial comment"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h = Hash.new
  h["note_display"] = s if s.length > 0
  h["note_type"] = "curatorial comment" if s.length > 0
  h["note_label"] = "Curatorial Comment" if s.length > 0
  a.push(h) if h.length > 0
  if a.length == 0
    h = Hash.new
    h["note_display"] = ""
    h["note_type"] = ""
    h["note_label"] = ""
    a.push(h)
  end
  solrjson["notes"] = a

  #consider vending ISO 639 zxx "no linguistic content" language code
  a = Array.new
  #no longer using language to describe metadata - v9
=begin
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet/lido:appellationValue[@lido:pref="preferred"]') { |x|
    unless x.nil? && x.attributes["xml:lang"].nil?
      code = x.attributes["xml:lang"]
      if code == "eng"
        lang = "English"
        uri = "http://id.loc.gov/vocabulary/languages/eng"
      else
        lang = "Non-english or no linguistic content"
      end
      h = Hash.new
      h["language_display"] = lang
      h["language_code"] = (code.nil? ? "" : code)
      h["language_URI"] = (uri.nil? ? [""] : [uri])
      a.push(h)
    end
  }
=end
  if a.length == 0
    h = Hash.new
    h["language_display"] = ""
    h["language_code"] = ""
    h["language_URI"] = [""]
    a.push(h)
  end
  solrjson["languages"] = a

  a = Array.new
  xml_desc.elements.each('lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace') { |x|
    i = i + 1

    a1 = Array.new
    x.elements.each('lido:place/lido:namePlaceSet/lido:appellationValue') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    a2 = Array.new
    x.elements.each('lido:place/lido:placeID[@lido:source="TGN"]') { |x2|
      a2.push("http://vocab.getty.edu/page/tgn/#{x2.text}") unless x2.text.nil?
    }
    a3 = Array.new
    x.elements.each('lido:place/lido:placeID') { |x2|
      unless x2.attributes["lido:type"].nil?
        att = x2.attributes["lido:type"]
        a3.push(att)
      end
    }

    a4 = Array.new
    x.elements.each('lido:place[@lido:geographicalEntity="geographic location"]/lido:gml/gml:Point/gml:coordinates') { |x2|
      a4.push(x2.text.strip) unless x2.text.nil?
    }

    a5 = Array.new
    x.elements.each('lido:place') { |x2|
      unless x2.attributes["lido:geographicalEntity"].nil?
        a5.push(x2.attributes["lido:geographicalEntity"])
      end
    }

    h = Hash.new
    h["place_display"] = (a1.length > 0 ? a1[0] : "")
    h["place_URI"] = (a2.length > 0 ? a2 : [""])
    h["place_role_label"] = (get_place_role(a3[0]).length > 0 ? get_place_role(a3[0]) : "")
    h["place_role_code"] = ""
    h["place_role_URI"] = [""]
    h["place_type_display"] = ""
    h["place_type_URI"] = [""]
    h["place_coordinates_display"] = (a4.length > 0 ? wktize(a4) : [""])
    h["place_coordinates_type"] = (a4.length > 0 ? wkttype(a4) : [""])
    #h["place_type_display"] = a5[0] if a5.length > 0 #suppressed until better metadata
    a.push(h) if h.length > 0

  }
  if a.length==0
    h = Hash.new
    h["place_display"] = ""
    h["place_URI"] = [""]
    h["place_role_label"] = ""
    h["place_role_code"] = ""
    h["place_role_URI"] = [""]
    h["place_type_display"] = ""
    h["place_type_URI"] = [""]
    h["place_coordinates_display"] = [""]
    h["place_coordinates_type"] = [""]
    a.push(h) if h.length > 0
  end
  solrjson["places"] = a if a.length > 0

  a = Array.new
  s = String.new
  h = Hash.new
  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:displayDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["date_display"] = (s.length > 0 ? s : "")
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:earliestDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["date_earliest"] = (s.length > 0 && s!="0" ? s : "")
  h["year_earliest"] = h["date_earliest"]
  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:latestDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["date_latest"] = (s.length > 0 && s!="0" ? s : "")
  h["year_latest"] = h["date_latest"]
  h["date_role_label"] = (h["date_display"].length > 0 ? "created" : "")
  h["date_role_code"] = ""
  h["date_role_URI"] = (h["date_role_label"].length > 0 ? get_date_role_authority(h["date_role_label"]) : [""])
  a.push(h) if h.length > 0
  if a.length==0
    h = Hash.new
    h["date_display"] = ""
    h["date_earliest"] = ""
    h["year_earliest"] = ""
    h["date_latest"] = ""
    h["year_latest"] = ""
    h["date_role_label"] = ""
    h["date_role_code"] = ""
    h["date_role_URI"] = ""
  end
  solrjson["dates"] = a if a.length > 0

  a = Array.new #for both subject topic and subject name
  xml_desc.elements.each('lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectActor') { |x|
    i = i + 1
    #puts "X:#{x}"

    a1 = Array.new
    x.elements.each('lido:displayActor') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    a2 = Array.new
    x.elements.each('lido:actor/lido:actorID[@lido:source="ULAN"]') { |x2|
      #puts "url:#{x2.text}"
      unless x2.attributes["lido:source"].nil? || x2.text.nil?
        source = x2.attributes["lido:source"]
        a2.push("http://vocab.getty.edu/page/ulan/#{x2.text.strip}") if source == "ULAN"
        a2.push("https://viaf.org/viaf#{x2.text.strip}") if source == "VIAF"
      end
    }

    h = Hash.new
    h["subject_heading_display"] = (a1.length > 0 ? cap_first_letter(a1[0]) : "")
    h["subject_heading_sortname"] = (a1.length > 0 ? a1[0] : "")
    h["subject_heading_URI"] = (a2.length > 0 ? a2 : [""])
    h2 = Hash.new
    h2["facet_display"] = (a1.length > 0 ? a1[0] : "")
    h2["facet_type"] = (a1.length > 0 ? "person" : "")
    h2["facet_type_label"] = (a1.length > 0 ? "Person" : "")
    h2["facet_URI"] = (a2.length > 0 ? a2 : [""])
    h2["facet_role_label"] = (a1.length > 0 ? "depicted or about" : "")
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    h2["facet_coordinates_display"] = [""]
    h2["facet_coordinates_type"] = [""]
    h["subject_facets"] = [h2] if h2.length > 0
    a.push(h) if h.length > 0
  }

  #reuse array from above subject name block
  xml_desc.elements.each('lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectConcept') { |x|

    i = i + 1
    #puts "X:#{x}"

    a1 = Array.new
    x.elements.each('lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    a2 = Array.new
    x.elements.each('lido:conceptID[@lido:source="AAT"]') { |x2|
      #puts "url:#{x2.text}"
      unless x2.text.nil?
        s = x2.text.strip
        a2.push(normalize_aat(s))
      end
    }

    h = Hash.new
    h["subject_heading_display"] = (a1.length > 0 ? cap_first_letter(a1[0]) : "")
    h["subject_heading_sortname"] = (a1.length > 0 ? a1[0] : "")
    h["subject_heading_URI"] = (a2.length > 0 ? a2 : [""])
    h2 = Hash.new
    h2["facet_display"] = (a1.length > 0 ? a1[0] : "")
    h2["facet_type"] = (a1.length > 0 ? "topic" : "")
    h2["facet_type_label"] = (a1.length > 0 ? "Topic" : "")
    h2["facet_URI"] = (a2.length > 0 ? a2 : [""])
    h2["facet_role_label"] = (a1.length > 0 ? "depicted or about" : "")
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    h2["facet_coordinates_display"] = [""]
    h2["facet_coordinates_type"] = [""]
    h["subject_facets"] = [h2] if h2.length > 0
    a.push(h) if h.length > 0

  }

  #reuse array from above subject name block
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:culture') { |x|

    i = i + 1
    #puts "X:#{x}"

    a1 = Array.new
    x.elements.each('lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    a2 = Array.new
    x.elements.each('lido:conceptID[@lido:source="AAT"]') { |x2|
      #puts "url:#{x2.text}"
      unless x2.text.nil?
        s = x2.text.strip
        a2.push(normalize_aat(s))
      end
    }

    h = Hash.new
    h["subject_heading_display"] = (a1.length > 0 ? cap_first_letter(a1[0]) : "")
    h["subject_heading_sortname"] = (a1.length > 0 ? a1[0] : "")
    h["subject_heading_URI"] = (a2.length > 0 ? a2 : [""])
    h2 = Hash.new
    h2["facet_display"] = (a1.length > 0 ? a1[0] : "")
    h2["facet_type"] = (a1.length > 0 ? "culture" : "")
    h2["facet_type_label"] = (a1.length > 0 ? "Culture" : "")
    h2["facet_URI"] = (a2.length > 0 ? a2 : [""])
    h2["facet_role_label"] = (a1.length > 0 ? "depicted or about" : "")
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    h2["facet_coordinates_display"] = [""]
    h2["facet_coordinates_type"] = [""]
    h["subject_facets"] = [h2] if h2.length > 0
    a.push(h) if h.length > 0
  }

  #reuse array from above subject name block
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:periodName') { |x|

    i = i + 1
    #puts "X:#{x}"

    a1 = Array.new
    x.elements.each('lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }

    h = Hash.new
    h["subject_heading_display"] = (a1.length > 0 ? cap_first_letter(a1[0]) : "")
    h["subject_heading_sortname"] = (a1.length > 0 ? a1[0] : "")
    h["subject_heading_URI"] = [""]
    h2 = Hash.new
    h2["facet_display"] = (a1.length > 0 ? a1[0] : "")
    h2["facet_type"] = (a1.length > 0 ? "period" : "")
    h2["facet_type_label"] = (a1.length > 0 ? "Period" : "")
    h2["facet_URI"] = [""]
    h2["facet_role_label"] = (a1.length > 0 ? "depicted or about" : "")
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    h2["facet_coordinates_display"] = [""]
    h2["facet_coordinates_type"] = [""]
    h["subject_facets"] = [h2] if h2.length > 0
    a.push(h) if h.length > 0
  }

  #reuse array from above subject name block
  xml_desc.elements.each('lido:objectClassificationWrap/lido:objectWorkTypeWrap/lido:objectWorkType[lido:conceptID/@lido:type="Genre"]') { |x|

    a1 = Array.new
    x.elements.each('lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }

    h = Hash.new
    h["subject_heading_display"] = (a1.length > 0 ? cap_first_letter(a1[0]) : "")
    h["subject_heading_sortname"] = (a1.length > 0 ? a1[0] : "")
    h["subject_heading_URI"] = [""]
    h2 = Hash.new
    h2["facet_display"] = (a1.length > 0 ? a1[0] : "")
    h2["facet_type"] = (a1.length > 0 ? "genre" : "")
    h2["facet_type_label"] = (a1.length > 0 ? "Genre" : "")
    h2["facet_URI"] = [""]
    h2["facet_role_label"] = (a1.length > 0 ? "depicted or about" : "")
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    h2["facet_coordinates_display"] = [""]
    h2["facet_coordinates_type"] = [""]
    h["subject_facets"] = [h2] if h2.length > 0
    a.push(h) if h.length > 0
  }

  #reuse array from above subject name block
  xml_desc.elements.each('lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace') { |x|

    a1 = Array.new
    #a1.push(x.text.strip) unless x.text.nil?
    x.elements.each('lido:displayPlace') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }

    a2 = Array.new
    x.elements.each('lido:place/lido:gml/gml:Point/gml:coordinates') { |x2|
      a2.push(x2.text.strip) unless x2.text.nil?
    }

    h = Hash.new
    h["subject_heading_display"] = (a1.length > 0 ? cap_first_letter(a1[0]) : "")
    h["subject_heading_sortname"] = (a1.length > 0 ? a1[0] : "")
    h["subject_heading_URI"] = [""]
    h2 = Hash.new
    h2["facet_display"] = (a1.length > 0 ? a1[0] : "")
    h2["facet_type"] = (a1.length > 0 ? "place" : "")
    h2["facet_type_label"] = (a1.length > 0 ? "Place" : "")
    h2["facet_URI"] = [""]
    h2["facet_role_label"] = (a1.length > 0 ? "depicted or about" : "")
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    h2["facet_coordinates_display"] = (a2.length > 0 ? wktize(a2) : [""])
    h2["facet_coordinates_type"] = (a2.length > 0 ? wkttype(a2) : [""])
    h["subject_facets"] = [h2] if h2.length > 0
    a.push(h) if h.length > 0
  }

  if a.length == 0
    h = Hash.new
    h["subject_heading_display"] = ""
    h["subject_heading_sortname"] = ""
    h["subject_heading_URI"] = [""]
    h2 = Hash.new
    h2["facet_display"] = ""
    h2["facet_type"] = ""
    h2["facet_type_label"] = ""
    h2["facet_URI"] = [""]
    h2["facet_role_label"] = ""
    h2["facet_role_code"] = ""
    h2["facet_role_URI"] = [""]
    hh2["facet_coordinates_display"] = [""]
    h2["facet_coordinates_type"] = [""]
    h["subject_facets"] = [h2]
    a.push(h)
  end
  solrjson["subjects"] = a if a.length > 0

  a = Array.new
  h = Hash.new
  s = String.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["campus_division"] = (s.length > 0 ? [s] : [""])

  h["collections"] = (set_spec.length > 0 ? [get_collection(set_spec)] : [""])

  s = String.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="On view or not"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["access_in_repository"] = (s.length > 0 ? [s] : [""])

  a2 = Array.new
  #xml_root.elements.each('lido:administrativeMetadata/lido:recordWrap/lido:recordInfoSet/lido:recordInfoLink[@lido:formatResource="html"]') { |x|
  #  a2.push(x.text.strip) unless x.text.nil?
  #}
  a2.push("https://collections.britishart.yale.edu/catalog/#{blacklight_id}") #TODO replace URL here
  h["access_in_repository_URI"] = (a2.length > 0 ? a2 : [""])

  h["access_contact_in_repository"] = get_access_contact

  #a2 = Array.new
  #xml_root.elements.each('lido:administrativeMetadata/lido:resourceWrap/lido:resourceSet/lido:resourceRepresentation/lido:linkResource') { |x|
  #  a2.push(x.text.strip) unless x.text.nil?
  #}
  #h["access_to_image_URI"] = (a2.length > 0 ? a2 : [""])

  images,manifests,captions = get_images(blacklight_id)
  ##h["access_to_primary_image_URI"] = (images.length > 0 ? images[0] : "")
  ##h["access_to_digital_assets_URI"] = (manifests.length > 0 ? manifests : [""])

  a.push(h) if h.length > 0
  solrjson["locations"] = a if a.length > 0


  a = Array.new
  a2 = Array.new #for digital_assets
  h = Hash.new
  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsType/lido:term[@lido:label="url"][../lido:conceptID/@lido:label="object copyright"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["original_rights_URI"] = (s.length > 0 ? [s] : [""])

  h["original_rights_notes"] = [""]

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsType/lido:term[not(@*)][../lido:conceptID/@lido:label="object copyright"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["original_rights_status_display"] = (s.length > 0 ? s : "")
  asset_rights_status_display = (s.length > 0 ? s : "")

  h["original_rights_type"] = "usage"
  h["original_rights_type_label"] = "Usage"

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet[lido:rightsType/lido:conceptID/@lido:label="object copyright"]/lido:creditLine') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["original_rights_copyright_credit_display"] = (s.length > 0 ? s : "")

  images.each_with_index do |image,i|
    #puts image
    h2 = Hash.new
    h2["asset_rights_status_display"] = asset_rights_status_display
    h2["asset_rights_notes"] = [""]
    h2["asset_rights_type"] = "usage"
    h2["asset_rights_type_label"] = "Usage"
    h2["asset_type"] = "image"
    h2["asset_URI"] = [image]
    h2["asset_flag"] = i == 0 ? "primary image" : ""
    h2["asset_caption_display"] = captions[i]
    a2.push(h2)
  end

  a.push(h) if h.length > 0
  if h.length == 0
    h = Hash.new
    h["original_rights_status_display"] = ""
    h["original_rights_notes"] = [""]
    h["original_rights_type"] = ""
    h["original_rights_type_label"] = ""
    h["original_rights_copyright_credit_display"] = ""
    h["original_rights_URI"] = [""]
    a.push(h) if h.length > 0
  end

  if a2.length == 0
    h2 = Hash.new
    h2["asset_rights_status_display"] = ""
    h2["asset_rights_notes"] = [""]
    h2["asset_rights_type"] = ""
    h2["asset_rights_type_label"] = ""
    h2["asset_type"] = ""
    h2["asset_URI"] = [""]
    h2["asset_flag"] = ""
    h2["asset_caption_display"] = ""
    a2.push(h2) if h2.length > 0
  end

  solrjson["rights"] = a
  solrjson["digital_assets"] = a2

#for v8 - move supertype to basic descriptors
=begin
  a = Array.new
  a2 = Array.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  a.each do |x|
    s = map_supertype2(x)
    h = Hash.new
    h["supertype"] = map_supertype1(s)
    h["supertype_level"] = "1"
    a2.push(h)
    h = Hash.new
    h["supertype"] = s
    h["supertype_level"] = "2"
    a2.push(h)

  end
=end
#for v7 - don't vend supertype 3
=begin
  a = Array.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:objectWorkTypeWrap/lido:objectWorkType/lido:term[../lido:conceptID/@lido:type="Object name"]') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  a.each do |x|
    h = Hash.new
    h["supertype"] = cap_first_letter(x.pluralize)
    h["supertype_level"] = "3"
    a2.push(h)
  end
=end
=begin
  if a2.length == 0
    h = Hash.new
    h["supertype"] = ""
    h["supertype_level"] = ""
    a2.push(h)
  end
  solrjson["supertypes"] = a2
=end

  a = Array.new
  h = Hash.new
  h["hierarchy_type"] = ""
  h["root_internal_identifier"] = ""
  h["descendant_count"] = ""
  h["maximum_depth"] = ""
  h["sibling_count"] = ""
  h["ancestor_internal_identifiers"] = [""]
  h["ancestor_URIs"] = [""]
  h["ancestor_display_names"] = [""]
  a.push(h)
  solrjson["hierarchies"] = a


  solrjson = JSON.pretty_generate(solrjson)
  #puts solrjson
  output_filename = "output2/#{filename.split("/")[1].split(".")[0]}.json"
  File.open(output_filename, 'w') { |file| file.write(solrjson) }
end

def test_empty
  id = 999999
  xml_str = '<lido:lido xmlns:lido="http://www.lido-schema.org" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gml="http://www.opengis.net/gml" xsi:schemaLocation="http://www.lido-schema.org http://www.lido-schema.org/schema/v1.0/lido-v1.0.xsd">
<lido:lidoRecID lido:source="Yale Center for British Art" lido:type="local">YCBA/lido-TMS-34</lido:lidoRecID>
<lido:category>
<lido:conceptID lido:type="URI">http://www.cidoc-crm.org/crm-concepts/#E22</lido:conceptID>
<lido:term xml:lang="eng">Man-Made Object</lido:term>
</lido:category>
<lido:descriptiveMetadata></lido:descriptiveMetadata></lido:lido>'
  set_spec = "ycba:ps"
  return id,xml_str,set_spec
end

def get_xml_from_db(id)
  @log.info "Getting xml for #{id}"
  q = "select xml from metadata_record where local_identifier = #{id}"
  s = @oai_client.query(q)
  xml_str = ""
  s.each do |row|
    xml_str = row["xml"]
  end
  q = "select set_spec from record_set_map where local_identifier = #{id}"
  s = @oai_client.query(q)
  set_spec = ""
  s.each do |row|
    set_spec = row["set_spec"] if row["set_spec"] != "ycba:incomplete"
  end
  #id,xml_str,set_spec = test_empty #for testing empty field (hijacks id's)
  create_json(id,xml_str,set_spec)
end

#DRIVER
objects = Array.new
#ids ="34, 80, 107, 120, 423, 471, 1480, 40392, 1489, 3579, 4908, 5001, 5005, 5054, 5981, 7632, 7935, 8783, 8867, 9836, " +
#    "10676,  11502, 11575, 11612, 15115, 15206, 19850, 21889, 21890, 21898, 22010, 24342, 26383, 26451, 28509, " +
#    "29334, 34363, 37054, 38435, 39101, 41109, 46623, 51708, 52176, 55318, 59577, 64421, 21891, 22015, 66162, 11575, 24058"
#ids = "66161"
#ids = "34,80,841"
#ids = "22015,5005,34"
#ids = "1475,80"
#ids = "24058"
#ids = "34,80,107,11575"
ids = "34,80"
#ids = "66533,66534,66535,66536,66537,66538,68846,82229,82230,34440,34442,74753,3849"

q = "select local_identifier from metadata_record where local_identifier in (#{ids})"
#q = "select local_identifier from metadata_record order by local_identifier asc"
s = @oai_client.query(q)
i = 0
s.each do |row|
  i = i + 1
  objects.push(row["local_identifier"].to_i)
end
@log.info "#{i.to_s} objects loaded to process"
objects.sort.each_with_index { |id, i|
  @log.info "At index #{i}" if i % 1000 == 0
  get_xml_from_db(id)
}

@oai_client.close
