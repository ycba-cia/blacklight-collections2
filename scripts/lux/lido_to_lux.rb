require 'rexml/document'
require 'json'

#loop on jdbc:mysql://oaipmh-prod.ctsmybupmova.us-east-1.rds.amazonaws.com/oaipmh2
#local properties file
#use database to only publish deltas?

filename = "testrecords/lido_34test.xml"
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
solrjson["agent"] = a if a.length > 0

a = Array.new
REXML::XPath.each(xml, '//lido:titleSet[@lido:type="Repository title"]/lido:appellationValue[@lido:pref="preferred"]') { |x|
  a.push(x.text)
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

solrjson = JSON.pretty_generate(solrjson)
puts solrjson
output_filename = "output/#{filename.split("/")[1].split(".")[0]}.json"
File.open(output_filename, 'w') { |file| file.write(solrjson) }

#scrap code here
#filejson = eval(mainh ash.to_json)
#filejson = JSON.pretty_generate(filejson)
#ort = REXML::XPath.first(xml, '//lido:rightsWorkSet/lido:rightsType/lido:conceptID[@lido:type="object copyright"]')