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
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:workID[@lido:type="inventory number"]') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["identifier_external"] = a if a.length > 0


  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
    a.push("tms:#{x.text.strip}") unless x.text.nil?
  }
  #
  solrjson["identifier_internal"] = a if a.length > 0

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

    h = Hash.new
    h["agent"] = a1 if a1.length > 0
    h["agent_identifier_URI"] = a2 if a2.length > 0
    h["agent_role_URI"] = a3 if a3.length > 0
    h["agent_display"] = a4 if a4.length > 0
    h["agent_sort"] = i
    #a.push({"agent" => a1,"agent_identifier_URI" => a2},"agent_role_URI" => a3)
    a.push(h) if h.length > 0
  }
  solrjson["agents"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:titleWrap/lido:titleSet[@lido:type="Repository title"]/lido:appellationValue[@lido:pref="preferred"]') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["title"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:displayStateEditionWrap/displayState|displayEdition') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["edition"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventMaterialsTech/lido:materialsTech/lido:termMaterialsTech/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["materials"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:culture/lido:term') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["culture"] = a if a.length > 0

  a = Array.new
  xml_root.elements.each('lido:descriptiveMetadata') { |x|
    unless x.nil? && x.attributes["xml:lang"].nil?
      code = x.attributes["xml:lang"]
      if code == "eng"
        lang = "English"
      else
        lang = "Non-english"
      end
      a.push(lang)
    end
  }
  solrjson["language_of_cataloging"] = a if a.length > 0

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

    h = Hash.new
    h["place"] = a1 if a1.length > 0
    h["place_URI"] = a2 if a2.length > 0
    h["place_type"] = a3 if a3.length > 0
    a.push(h) if h.length > 0

  }
  solrjson["places"] = a if a.length > 0

  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:earliestDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["date_earliest"] = s if s.length > 0

  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:latestDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["date_latest"] = s if s.length > 0

  s = String.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:displayDate') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["date_display_string"] = s if s.length > 0

  a = Array.new
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
    h["subject_name"] = a1 if a1.length > 0
    h["subject_name_URI"] = a2 if a2.length > 0
    a.push(h) if h.length > 0
  }
  solrjson["subjects_name"] = a if a.length > 0

  a = Array.new
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
    h["subject_topic"] = a1 if a1.length > 0
    h["subject_topic_URI"] = a2 if a2.length > 0
    a.push(h) if h.length > 0

  }
  solrjson["subjects_topic"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace') { |x|
    i = i + 1

    a1 = Array.new
    x.elements.each('lido:displayPlace') { |x2|
      a1.push(x2.text) unless x2.text.nil?
    }
    a2 = Array.new
    x.elements.each('lido:place/lido:placeID[@lido:source="TGN"]') { |x2|
      #puts "url:#{x2.text}"
      a2.push("http://vocab.getty.edu/page/tgn/#{x2.text}") unless x2.text.nil?
    }

    a3 = Array.new
    x.elements.each('lido:place/lido:placeID') { |x2|
      att = x2.attributes["lido:type"] unless x2.attributes["lido:type"].nil?
      a3.push(att)
    }

    h = Hash.new
    h["subject_geographic"] = a1 if a1.length > 0
    h["subject_geographic_uri"] = a2 if a2.length > 0
    h["subject_geographic_type"] = a3 if a3.length > 0
    a.push(h) if h.length > 0

  }
  solrjson["subjects_geographic"] = a if a.length > 0

  s = String.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["repository"] = s if s.length > 0

  s = String.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["collection_within_repository"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsType/lido:term[@lido:label="url"][../lido:conceptID/@lido:label="object copyright"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["restrictions_on_item"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:creditLine[../lido:rightsHolder/lido:legalBodyID/@lido:label="Rights Holder"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["credit_line"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:administrativeMetadata/lido:recordWrap/lido:recordInfoSet/lido:recordInfoLink[@lido:formatResource="html"]') { |x|
    s = x.text.strip unless x.text.nil?
  }
  solrjson["URI_to_item_in_local_system"] = s if s.length > 0

  a = Array.new
  xml_root.elements.each('lido:administrativeMetadata/lido:resourceWrap/lido:resourceSet/lido:resourceRepresentation/lido:linkResource') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["URI_to_image_of_item"] = a if a.length > 0

  a = Array.new
  xml_root.elements.each('lido:administrativeMetadata/lido:resourceWrap/lido:resourceSet/lido:resourceRepresentation/lido:linkResource') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["URI_to_image_of_item"] = a if a.length > 0

  a = Array.new
  xml_desc.elements.each('lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace/lido:place[@lido:geographicalEntity="geographic location"]/lido:gml/gml:Point/gml:coordinates') { |x|
    a.push(x.text.strip) unless x.text.nil?
  }
  solrjson["coordinates"] = a if a.length > 0

  solrjson = JSON.pretty_generate(solrjson)
  puts solrjson
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
ids ="34, 80, 107, 120, 423, 471, 1480, 40392, 1489, 3579, 4908, 5001, 5054, 5981, 7632, 7935, 8783, 8867, 9836, " +
    "10676,  11502, 11575, 11612, 15115, 15206, 19850, 21889, 21890, 21898, 22010, 24342, 26383, 26451, 28509, " +
    "29334, 34363, 37054, 38435, 39101, 41109, 46623, 51708, 52176, 55318, 59577, 64421, 21891, 22015, 66162"
ids = "34,5005"
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
