require 'rexml/document'
require 'json'

#loop on jdbc:mysql://oaipmh-prod.ctsmybupmova.us-east-1.rds.amazonaws.com/oaipmh2
#local properties file
#use database to only publish deltas?

filename = "testrecords/lido_34public.xml"
file = File.new(filename)
xml = REXML::Document.new(file)
solrjson = Hash.new

a = Array.new
REXML::XPath.each(xml, '//lido:workID[@lido:type="inventory number"]') { |x|
  a.push(x.text)
}
#puts "identifier_external: #{a.inspect}"
solrjson["identifier_external"] = a #NOTE: required

a = Array.new
REXML::XPath.each(xml, '//lido:descriptiveMetadata/lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
  a.push("tms:#{x.text}")
}
#puts "identifier_internal: #{a.inspect}"
solrjson["identifier_internal"] = a #NOTE: required

a = Array.new
i = 0
REXML::XPath.each(xml, '//lido:event[lido:eventType/lido:term="production"]/lido:eventActor') { |x|
  i = i + 1
  a1 = Array.new
  x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:pref="preferred"]') { |x2|
    a1.push(x2.text)
  }
  a2 = Array.new
  x.elements.each('lido:actorInRole/lido:actor/lido:actorID[@lido:type="url"]') { |x2|
    #puts "url:#{x2.text}"
    a2.push(x2.text)
  }

  a3 = Array.new
  x.elements.each('lido:actorInRole/lido:roleActor[lido:conceptID/@lido:type="Object related role"]/lido:term') { |x2|
    a3.push(x2.text)
  }
  a4 = Array.new
  x.elements.each('lido:displayActorInRole') { |x2|
    a4.push(x2.text)
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
REXML::XPath.each(xml, '//lido:titleSet[@lido:type="Repository title"]/lido:appellationValue[@lido:pref="preferred"]') { |x|
  a.push(x.text.strip)
}

solrjson["title"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:objectIdentificationWrap/lido:displayStateEditionWrap/displayState|displayEdition') { |x|
  a.push(x.text)
}
solrjson["edition"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:eventWrap/lido:eventSet/lido:event/lido:eventMaterialsTech/lido:materialsTech/lido:termMaterialsTech/lido:term') { |x|
  a.push(x.text)
}
solrjson["materials"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:event[lido:eventType/lido:term="production"]/lido:culture/lido:term') { |x|
  a.push(x.text)
}
solrjson["culture"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:descriptiveMetadata/@xml:lang') { |x|
  a.push(x)
}
solrjson["language_of_cataloging"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace') { |x|
  i = i + 1

  a1 = Array.new
  x.elements.each('lido:place/lido:namePlaceSet/lido:appellationValue') { |x2|
    a1.push(x2.text)
  }
  a2 = Array.new
  x.elements.each('lido:place/lido:placeID[@lido:source="TGN"]') { |x2|
    #puts "url:#{x2.text}"
    a2.push("http://vocab.getty.edu/page/tgn/#{x2.text}")
  }

  a3 = Array.new
  x.elements.each('lido:place/lido:placeID') { |x2|
    att = x2.attributes["lido:type"]
    a3.push(att)
  }

  h = Hash.new
  h["place"] = a1 if a1.length > 0
  h["place_URI"] = a2 if a2.length > 0
  h["place_type"] = a3 if a3.length > 0
  a.push(h) if h.length > 0

}
solrjson["places"] = a if a.length > 0

s = REXML::XPath.first(xml, '//lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:earliestDate')
solrjson["date_earliest"] = s.text unless s.nil?

s = REXML::XPath.first(xml, '//lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:date/lido:latestDate')
solrjson["date_latest"] = s.text unless s.nil?

s = REXML::XPath.first(xml, '//lido:event[lido:eventType/lido:term="production"]/lido:eventDate/lido:displayDate')
solrjson["date_display_string"] = s.text unless s.nil?

a = Array.new
REXML::XPath.each(xml, '//lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectActor') { |x|

  i = i + 1
  #puts "X:#{x}"

  a1 = Array.new
  x.elements.each('lido:displayActor') { |x2|
    a1.push(x2.text)
  }
  a2 = Array.new
  x.elements.each('lido:actor/lido:actorID[@lido:source="ULAN"]') { |x2|
    #puts "url:#{x2.text}"
    a2.push("http://vocab.getty.edu/page/ulan/#{x2.text}")
  }

  h = Hash.new
  h["subject_name"] = a1 if a1.length > 0
  h["subject_name_URI"] = a2 if a2.length > 0
  a.push(h) if h.length > 0

}
solrjson["subjects_name"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectConcept') { |x|

  i = i + 1
  #puts "X:#{x}"

  a1 = Array.new
  x.elements.each('lido:term') { |x2|
    a1.push(x2.text)
  }
  a2 = Array.new
  x.elements.each('lido:conceptID[@lido:source="AAT"]') { |x2|
    #puts "url:#{x2.text}"
    s = x2.text
    s = "30000" + s if s.length == 4
    s = "3000" + s if s.length == 5
    s = "300" + s if s.length == 6
    a2.push("http://vocab.getty.edu/page/aat/#{s}")
  }

  h = Hash.new
  h["subject_topic"] = a1 if a1.length > 0
  h["subject_topic_URI"] = a2 if a2.length > 0
  a.push(h) if h.length > 0

}
solrjson["subjects_topic"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace') { |x|
  i = i + 1

  a1 = Array.new
  x.elements.each('lido:displayPlace') { |x2|
    a1.push(x2.text)
  }
  a2 = Array.new
  x.elements.each('lido:place/lido:placeID[@lido:source="TGN"]') { |x2|
    #puts "url:#{x2.text}"
    a2.push("http://vocab.getty.edu/page/tgn/#{x2.text}")
  }

  a3 = Array.new
  x.elements.each('lido:place/lido:placeID') { |x2|
    att = x2.attributes["lido:type"]
    a3.push(att)
  }

  h = Hash.new
  h["subject_geographic"] = a1 if a1.length > 0
  h["subject_geographic_uri"] = a2 if a2.length > 0
  h["subject_geographic_type"] = a3 if a3.length > 0
  a.push(h) if h.length > 0

}
solrjson["subjects_geographic"] = a if a.length > 0

s = REXML::XPath.first(xml, '//lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]')
solrjson["repository"] = s.text unless s.nil?

s = REXML::XPath.first(xml, '//lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term')
solrjson["collection_within_repository"] = s.text unless s.nil?

s = REXML::XPath.first(xml, '//lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:rightsType/lido:term[@lido:label="url"][../lido:conceptID/@lido:label="object copyright"]')
solrjson["restrictions_on_item"] = s.text unless s.nil?

s = REXML::XPath.first(xml, '//lido:administrativeMetadata/lido:rightsWorkWrap/lido:rightsWorkSet/lido:creditLine[../lido:rightsHolder/lido:legalBodyID/@lido:label="Rights Holder"]')
solrjson["credit_line"] = s.text unless s.nil?

s = REXML::XPath.first(xml, '//lido:recordWrap/lido:recordInfoSet/lido:recordInfoLink[@lido:formatResource="html"]')
solrjson["URI_to_item_in_local_system"] = s.text.strip unless s.nil?

a = Array.new
REXML::XPath.each(xml, '//lido:resourceSet/lido:resourceRepresentation/lido:linkResource') { |x|
  a.push(x.text.strip)
}
solrjson["URI_to_image_of_item"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:objectRelationWrap/lido:subjectWrap/lido:subjectSet/lido:subject[@lido:type="description"]/lido:subjectPlace/lido:place[@lido:geographicalEntity="geographic location"]/lido:gml/gml:Point/gml:coordinates') { |x|
  a.push(x.text)
}
solrjson["coordinates"] = a if a.length > 0

solrjson = JSON.pretty_generate(solrjson)
puts solrjson
output_filename = "output/#{filename.split("/")[1].split(".")[0]}.json"
File.open(output_filename, 'w') { |file| file.write(solrjson) }

#scrap code here
#filejson = eval(mainh ash.to_json)
#filejson = JSON.pretty_generate(filejson)
#ort = REXML::XPath.first(xml, '//lido:rightsWorkSet/lido:rightsType/lido:conceptID[@lido:type="object copyright"]')