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
solrjson["identifier_external"] = a

a = Array.new
REXML::XPath.each(xml, '//lido:descriptiveMetadata/lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
  a.push("tms:#{x.text}")
}
#puts "identifier_internal: #{a.inspect}"
solrjson["identifier_internal"] = a

a = Array.new
REXML::XPath.each(xml, '//lido:event[lido:eventType/lido:term="production"]/lido:eventActor') { |x|
  a1 = Array.new
  x.elements.each('lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[@lido:pref="preferred"]') { |x2|
    a1.push(x2.text)
  }
  a2 = Array.new
  x.elements.each('lido:actorInRole/lido:actor/lido:actorID[@lido:type="url"]') { |x2|
    #puts "url:#{x2.text}"
    a2.push(x2.text)
  }
  #TODO - rest on agent children here
  a.push({"agent" => a1,"agent_identifier_URI" => a2})
}
solrjson["agent"] = a

solrjson = JSON.pretty_generate(solrjson)
puts solrjson
output_filename = "output/#{filename.split("/")[1].split(".")[0]}.json"
File.open(output_filename, 'w') { |file| file.write(solrjson) }

#scrap code here
#filejson = eval(mainh ash.to_json)
#filejson = JSON.pretty_generate(filejson)
#ort = REXML::XPath.first(xml, '//lido:rightsWorkSet/lido:rightsType/lido:conceptID[@lido:type="object copyright"]')