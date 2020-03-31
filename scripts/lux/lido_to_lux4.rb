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
oai_databasename = "oaipmh2"
sslca = "#{rails_root}/#{y['awscert']}"
#puts "PW:#{oai_password}"
puts "SSLCA:#{sslca}"
@oai_client = Mysql2::Client.new(:host=>oai_hostname,:username=>oai_username,:password=>oai_password,:database=>oai_databasename,:sslca=>sslca)
puts "oaipmh ping:#{@oai_client.ping}"
#TODO: configure the streaming query in the driver

#METHODS
def create_json(id,xml_str)
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
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventActor') { |x|
    i = i + 1
    a1 = Array.new
    x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:pref="preferred"]') { |x2|
      a1.push(x2.text.strip) unless x2.text.nil?
    }
    a2 = Array.new
    x.elements.each('lido:actorInRole/lido:actor/lido:actorID[@lido:type="url"]') { |x2|
      #puts "url:#{x2.text}"
      a2.push(x2.text.strip) unless x2.text.nil?
    }

    a3 = Array.new
    x.elements.each('lido:actorInRole/lido:roleActor[lido:conceptID/@lido:type="Object related role"]/lido:term') { |x2|
      #puts "X2:#{x2.text.nil?}"
      a3.push(x2.text.strip) unless x2.text.nil?
    }
    a4 = Array.new
    x.elements.each('lido:displayActorInRole') { |x2|
      a4.push(x2.text.strip) unless x2.text.nil?
    }
    a5 = Array.new
    x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:label="Alpha Sort"]') { |x2|
      a5.push(x2.text.strip) unless x2.text.nil?
    }
    a6 = Array.new
    x.elements.each('lido:actorInRole/lido:actor') { |x2|
      unless x2.nil? && x2.attributes["lido:type"].nil?
        a6.push(x2.attributes["lido:type"])
      end
    }

    h = Hash.new
    #h["agent"] = a1[0] if a1.length > 0
    h["agent_URI"] = a2 if a2.length > 0
    h["agent_role_URI"] = a3[0] if a3.length > 0
    h["agent_display"] = a4[0] if a4.length > 0
    h["agent_relevance"] = i
    h["agent_sortname"] = a5[0] if a5.length > 0
    h["agent_type_display"] = a6[0] if a6.length > 0
    #a.push({"agent" => a1,"agent_identifier_URI" => a2},"agent_role_URI" => a3)
    a.push(h) if h.length > 0
  }
  solrjson["agents"] = a if a.length > 0

  a = Array.new
  a1 = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet[@lido:type="Repository title"]/lido:appellationValue[@lido:pref="preferred"]') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["title_display"] = a1[0] if a1.length > 0
  h["title_type"] = "preferred"
  a.push(h)
  a1 = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet/lido:appellationValue[@lido:pref="alternate"]') { |x|
    a1.push(x.text.strip) unless x.text.nil?
  }
  h = Hash.new
  h["title_display"] = a1[0] if a1.length > 0
  h["title_type"] = "alternate"
  a.push(h)
  solrjson["titles"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:displayStateEditionWrap/displayState|displayEdition') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["edition_display"] = a[0] if a.length > 0

=begin
  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventActor') { |x|
    x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:pref="preferred"]') { |x2|
      puts x2.text.strip unless x.text.nil?
    }
    x.elements.each('lido:actorInRole/lido:roleActor/lido:conceptID') { |x3|
      puts x3
      #puts x3.text.strip unless x.text.nil?
    }
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["imprint_display"] = a if a.length > 0
=end

  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventMaterialsTech/lido:materialsTech/lido:termMaterialsTech/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["materials_display"] = a if a.length > 0

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
      h["measurement_unit"] = s3 if s3.length > 0
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
    h["place_lation_type"] = a3[0] if a3.length > 0
    h["place_lation"] = a4[0] if a4.length > 0
    h["place_type"] = a5[0] if a5.length > 0
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
  h["date_display"] = s if s.length > 0
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
      a2.push("http://vocab.getty.edu/page/ulan/#{x2.text.strip}") unless x2.text.nil?
    }

    h = Hash.new
    h["subject_heading_display"] = a1[0] if a1.length > 0
    h["subject_URI"] = a2[0] if a2.length > 0
    h2 = Hash.new
    h2["facet_display"] = a1[0] if a1.length > 0
    h2["facet_type"] = "name"
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
        s = "30000" + s if s.length == 4
        s = "3000" + s if s.length == 5
        s = "300" + s if s.length == 6
        a2.push("http://vocab.getty.edu/page/aat/#{s}")
      end
    }

    h = Hash.new
    h["subject_heading_display"] = a1[0] if a1.length > 0
    h["subject_URI"] = a2[0] if a2.length > 0
    h2 = Hash.new
    h2["facet_display"] = a1[0] if a1.length > 0
    h2["facet_type"] = "topic"
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

  s = String.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    s = x.text.strip unless x.text.nil?
  }
  h["collection_within_repository"] = s if s.length > 0

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
  create_json(id,xml_str)
end

#DRIVER
objects = Array.new
#ids ="34, 80, 107, 120, 423, 471, 1480, 40392, 1489, 3579, 4908, 5001, 5054, 5981, 7632, 7935, 8783, 8867, 9836, " +
    "10676,  11502, 11575, 11612, 15115, 15206, 19850, 21889, 21890, 21898, 22010, 24342, 26383, 26451, 28509, " +
    "29334, 34363, 37054, 38435, 39101, 41109, 46623, 51708, 52176, 55318, 59577, 64421, 21891, 22015, 66162"
ids = "22015"
#ids = "34"
#ids = "22015,80,34"
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