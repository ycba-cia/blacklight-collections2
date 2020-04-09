require 'rexml/document'
require 'json'
require 'yaml'
require 'mysql2'

#CONFIG
rails_root = "/Users/ermadmix/Documents/RubymineProjects/blacklight-collections2"
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
def get_primary_supertype(s)
  d2 = Array.new
  d2.push("Painting")
  d2.push("Brass Rubbing")
  d2.push("Drawing & Watercolor")
  d2.push("Drawing & Watercolor-Architectural")
  d2.push("Drawing & Watercolor-Miniature")
  d2.push("Drawing & Watercolor-Sketchbook")
  d2.push("Photograph")
  d2.push("Poster")
  d2.push("Print")
  d2.push("Print-printing-plate")
  d3 = Array.new
  d3.push("Ceramic")
  d3.push("Model")
  d3.push("Painted Object")
  d3.push("Sculpture")
  d3.push("Silver")
  d3.push("Wedgwood")
  d3.push("Paint Box")

  d1 = "X-Dimensional Object"
  d1 = "Two-Dimensional Object" if d2.include?(s)
  d1 = "Three-Dimensional Object" if d3.include?(s)
  d1
end
def get_collection(s)
  c = ""
  c = "Frames" if s == "ycba:frames"
  c = "Prints and Drawings" if s == "ycba:pd"
  c = "Paintings and Sculpture" if s == "ycba:ps"
  c
end
def get_access_contact
  "ycbaonline@yale.edu"
end
def get_date_role_authority(s)
  a = ""
  a = "http://vocab.getty.edu/page/aat/300435447" if s == "created"
  a
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
  h["identifier_display"] = "YCBA #{a[0]}" if a.length > 0 #not-multivalued
  h["identifier_type"] = "Accession Number"
  a2.push(h) if h.length > 0
  h = Hash.new
  h["identifier_value"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_display"] = "YCBA_#{a[0]}" if a.length > 0 #not-multivalued
  h["identifier_type"] = "system"
  a2.push(h) if h.length > 0


  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["identifier_value"] = a[0] if a.length > 0 #not-multivalued
  h["identifier_type"] = "TMS ObjectID"
  a2.push(h)
  solrjson["identifiers"] = a2 if a2.length > 0

  a = Array.new
  i = 0
  xml_desc.elements.each('lido:eventWrap/lido:eventSet') { |x|
    #i = i + 1

    a1 = Array.new
    x.elements.each('lido:event/lido:eventType/lido:term') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    next if a1.length > 0 && a1[0] == "Curatorial comment"

    a2 = Array.new
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
      x2.elements.each('lido:actorInRole/lido:actor') { |x3|
        unless x3.nil? && x3.attributes["lido:type"].nil?
          a8.push(x3.attributes["lido:type"])
        end
      }
      h = Hash.new
      i = i + 1
      h["agent_display"] = a3[0] if a3.length > 0
      h["agent_sortname"] = a4[0] if a4.length > 0
      h["agent_URI"] = a5 if a5.length > 0
      h["agent_role_display"] = a6[0] if a6.length > 0
      h["agent_role_URI"] = a7[0] if a7.length > 0
      h["agent_type_display"] = a8[0] if a8.length > 0
      h["agent_type_URI"] = get_agent_type_authority(a8[0]) if a8.length > 0
      h["agent_sort"] = i
      a2.push(h) if h.length > 0
    }
    a.push(a2) if a2.length > 0
  }
  solrjson["agents"] = a if a.length > 0

  a = Array.new
  a1 = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet[@lido:type="Repository title"]/lido:appellationValue[@lido:pref="preferred"]') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["title_display"] = a1[0] if a1.length > 0
  h["title_type"] = "preferred" if a1.length > 0
  a.push(h)
  a1 = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet/lido:appellationValue[@lido:pref="alternate"]') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["title_display"] = a1[0] if a1.length > 0
  h["title_type"] = "alternate" if a1.length > 0
  a.push(h)
  solrjson["titles"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:displayStateEditionWrap/displayState|displayEdition') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["edition_display"] = a[0] if a.length > 0


  a = Array.new
  test = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventActor') { |x|
    #x.elements.each('lido:displayActorInRole') { |x2|
    #  a.push(x2.text.strip) unless x2.text.nil?
    #}
    x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:pref="preferred"]') { |x2|
      a.push(x2.text.strip) unless x2.text.nil?
    }
    x.elements.each('lido:actorInRole/lido:roleActor/lido:term[../lido:conceptID[@lido:type="Object related role"]]') { |x2|
      test = x2.text.strip unless x2.text.nil?
    }
    #a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["imprint_display"] = a[0] if a.length > 0 && test=="publisher"


  a = Array.new
  a1 = Array.new
  h = Hash.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventMaterialsTech/lido:displayMaterialsTech') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h["materials_display"] = a1[0] if a1.length > 0
  #solrjson["materials_display"] = a if a.length > 0

  a1 = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventMaterialsTech/lido:materialsTech/lido:termMaterialsTech/lido:term') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h["materials"] = a1 if a1.length > 0
  a.push(h)
  solrjson["materials"] = a if a.length > 0

=begin
  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:culture/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["culture"] = a if a.length > 0
=end

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:objectMeasurementsWrap/lido:objectMeasurementsSet') { |x|

    s = String.new
    x.elements.each('lido:displayObjectMeasurements') { |x2|
      s =  x2.text.strip unless x2.text.nil?
    }

    a2 = Array.new
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
      h["measurement_type"] = s2 if s2.length > 0
      h["measurement_type_URI"] = get_measurement_type_authority(s2) if s2.length > 0
      h["measurement_unit"] = s3 if s3.length > 0
      h["measurement_unit_URI"] = get_measurement_authority(s3) if get_measurement_authority(s3).length > 0
      h["measurement_value"] = s4 if s4.length > 0
      a2.push(h)
    }
    h2 = Hash.new
    h2["measurement_display"] = s if s.length > 0
    h2["measurements"] = a2 if a2.length > 0
    a.push(h2)
  }
  solrjson["measurements"] = a if a.length > 0

  a = Array.new
  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:displayEvent[../lido:event/lido:eventType/lido:term="Curatorial comment"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h = Hash.new
  h["note_display"] = s if s.length > 0
  h["note_type"] = "curatorial comment" if s.length > 0
  a.push(h) if h.length > 0
  s = String.new
  #xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:creditLine[../../lido:rightsWorkSet/lido:rightsType/lido:conceptID/@lido:label="object ownership"]') { |x|
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet[lido:rightsType/lido:conceptID/@lido:label="object ownership"]/lido:creditLine') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h = Hash.new
  h["note_display"] = s if s.length > 0
  h["note_type"] = "credit line" if s.length > 0
  a.push(h) if h.length > 0
  solrjson["note"] = a if a.length > 0

  a = Array.new
  xml_root.elements.each('lido:descriptiveMetadata') { |x|
    unless x.nil? && x.attributes["xml:lang"].nil?
      code = x.attributes["xml:lang"]
      if code == "eng"
        lang = "English"
      else
        lang = "Non-english"
      end
      h = Hash.new
      h["language_display"] = lang
      h["language_code"] = code
      a.push(h)
    end
  }
  solrjson["language"] = a if a.length > 0

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
    h["place_display"] = a1[0] if a1.length > 0
    h["place_URI"] = a2 if a2.length > 0
    h["place_role_display"] = get_place_role(a3[0]) if get_place_role(a3[0]).length > 0
    h["place_lation"] = a4[0] if a4.length > 0
    #h["place_type_display"] = a5[0] if a5.length > 0 #suppressed until better metadata
    a.push(h) if h.length > 0

  }
  solrjson["places"] = a if a.length > 0

  a = Array.new
  s = String.new
  h = Hash.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:earliestDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["date_earliest"] = s if s.length > 0
  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:latestDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["date_latest"] = s if s.length > 0
  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:displayDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["date_display"] = s if s.length > 0 if s.length > 0
  h["date_role_display"] = "created" if s.length > 0
  h["date_role_URI"] = get_date_role_authority(h["date_role_display"]) if s.length > 0
  a.push(h) if h.length > 0
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
    h["subject_heading_display"] = a1[0] if a1.length > 0
    h["subject_heading_sortname"] = a1[0] if a1.length > 0
    h["subject_URI"] = a2[0] if a2.length > 0
    h2 = Hash.new
    h2["facet_display"] = a1[0] if a1.length > 0
    h2["facet_type"] = "person"
    h2["facet_URI"] = a2[0] if a2.length > 0
    h2["facet_role_display"] = "depicted or about"
    h["subject_facets"] = h2 if h2.length > 0
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
    h["subject_heading_display"] = a1[0] if a1.length > 0
    h["subject_URI"] = a2[0] if a2.length > 0
    h2 = Hash.new
    h2["facet_display"] = a1[0] if a1.length > 0
    h2["facet_type"] = "topic"
    h2["facet_role_display"] = "depicted or about"
    h["subject_facets"] = h2 if h2.length > 0
    a.push(h) if h.length > 0

  }
  solrjson["subjects"] = a if a.length > 0

  a = Array.new
  h = Hash.new
  s = String.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["repository"] = s if s.length > 0

  h["collection_in_repository"] = get_collection(set_spec) if set_spec.length > 0

  s = String.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="On view or not"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["access_in_repository"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:recordWrap/lido:recordInfoSet/lido:recordInfoLink[@lido:formatResource="html"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["access_in_repository_URI"] = s if s.length > 0

  a2 = Array.new
  xml_root.elements.each('lido:administrativeMetadata/lido:resourceWrap/lido:resourceSet/lido:resourceRepresentation/lido:linkResource') { |x|
    a2.push(x.text.strip) unless x.text.nil?
  }
  h["access_to_image_URI"] = a2 if a2.length > 0
  h["access_contact_in_repository"] = get_access_contact
  a.push(h) if h.length > 0
  solrjson["locations"] = a if a.length > 0

  a = Array.new
  h = Hash.new
  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsType/lido:term[@lido:label="url"][../lido:conceptID/@lido:label="object copyright"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["rightsURI"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsHolder/lido:legalBodyName/lido:appellationValue[../../lido:legalBodyID/@lido:label="Rights Holder"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["rights_notes"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsType/lido:term[not(@*)][../lido:conceptID/@lido:label="object copyright"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["rights"] = s if s.length > 0
  a.push(h) if h.length > 0
  solrjson["usage_rights"] = a if s.length > 0

  a = Array.new
  a2 = Array.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  a.each do |x|
    h = Hash.new
    h["supertype"] = get_primary_supertype(x)
    h["supertype_level"] = 1
    a2.push(h)
    h = Hash.new
    h["supertype"] = x
    h["supertype_level"] = 2
    a2.push(h)

  end
  a = Array.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:objectWorkTypeWrap/lido:objectWorkType/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  a.each do |x|
    h = Hash.new
    h["supertype"] = x
    h["supertype_level"] = 3
    a2.push(h)
  end
  solrjson["supertypes"] = a2 if a2.length > 0

  solrjson = JSON.pretty_generate(solrjson)
  #puts solrjson
  output_filename = "output/#{filename.split("/")[1].split(".")[0]}.json"
  File.open(output_filename, 'w') { |file| file.write(solrjson) }
end

def get_xml_from_db(id)
  puts "Getting xml for #{id}"
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
  create_json(id,xml_str,set_spec)
end

#DRIVER
objects = Array.new
ids ="34, 80, 107, 120, 423, 471, 1480, 40392, 1489, 3579, 4908, 5001, 5054, 5981, 7632, 7935, 8783, 8867, 9836, " +
    "10676,  11502, 11575, 11612, 15115, 15206, 19850, 21889, 21890, 21898, 22010, 24342, 26383, 26451, 28509, " +
    "29334, 34363, 37054, 38435, 39101, 41109, 46623, 51708, 52176, 55318, 59577, 64421, 21891, 22015, 66162"
#ids = "21891"
#ids = "34,80"
#ids = "22015,5005,34"
q = "select local_identifier from metadata_record where local_identifier in (#{ids})"
#q = "select local_identifier from metadata_record"
s = @oai_client.query(q)
i = 0
s.each do |row|
  i = i + 1
  objects.push(row["local_identifier"])
end
puts "#{i.to_s} objects loaded to process"
objects.each_with_index { |id, i|
    puts "At index #{i}" if i % 1000 == 0
    get_xml_from_db(id)
}

@oai_client.close