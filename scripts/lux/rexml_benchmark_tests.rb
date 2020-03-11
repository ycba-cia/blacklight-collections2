require 'rexml/document'
require 'json'
require 'benchmark'

filename = "testrecords/lido_34public.xml"
file = File.new(filename)
xml = REXML::Document.new(file)

puts Benchmark.measure {
  solrjson = Hash.new

  a = Array.new
  REXML::XPath.each(xml, '//lido:workID[@lido:type="inventory number"]') { |x|
    a.push(x.text)
  }
  solrjson["identifier_external"] = a

  a = Array.new
  REXML::XPath.each(xml, '//lido:descriptiveMetadata/lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
    a.push("tms:#{x.text}")
  }
  #
  solrjson["identifier_internal"] = a

  s = REXML::XPath.first(xml, '//lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]')
  solrjson["repository"] = s.text unless s.nil?

  s = REXML::XPath.first(xml, '//lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term')
  solrjson["collection_within_repository"] = s.text unless s.nil?

  solrjson = JSON.pretty_generate(solrjson)
  puts solrjson
}
#0.790000   0.000000   0.790000 (  0.789564)

puts Benchmark.measure {
  solrjson = Hash.new

  xml_root = xml.root

  a = Array.new
  xml_root.elements.each('lido:descriptiveMetadata/lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:workID[@lido:type="inventory number"]') { |x|
    a.push(x.text)
  }
  solrjson["identifier_external"] = a

  a = Array.new
  xml_root.elements.each('lido:descriptiveMetadata/lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
    a.push("tms:#{x.text}")
  }
  #
  solrjson["identifier_internal"] = a

  s = String.new
  xml_root.elements.each('lido:descriptiveMetadata/lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]') { |x|
    s = x.text
  }
  solrjson["repository"] = s if s.length > 0

  s = String.new
  xml_root.elements.each('lido:descriptiveMetadata/lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    s = x.text
  }
  solrjson["collection_within_repository"] = s if s.length > 0

  solrjson = JSON.pretty_generate(solrjson)
  puts solrjson
}
#0.040000   0.000000   0.040000 (  0.045250)

puts Benchmark.measure {
  solrjson = Hash.new

  xml_root = xml.root
  xml_desc = xml_root.elements['lido:descriptiveMetadata']

  #puts xml_desc
  a = Array.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:workID[@lido:type="inventory number"]') { |x|
    a.push(x.text)
  }
  solrjson["identifier_external"] = a

  a = Array.new
  xml_desc.elements.each('lido:eventWrap/lido:eventSet/lido:event/lido:eventID[@lido:type="TMS"][../lido:eventType/lido:term/text() = "production"]') { |x|
    a.push("tms:#{x.text}")
  }
  #
  solrjson["identifier_internal"] = a

  s = String.new
  xml_desc.elements.each('lido:objectIdentificationWrap/lido:repositoryWrap/lido:repositorySet/lido:repositoryLocation/lido:partOfPlace/lido:namePlaceSet/lido:appellationValue[@lido:label="Site"]') { |x|
    s = x.text
  }
  solrjson["repository"] = s if s.length > 0

  s = String.new
  xml_desc.elements.each('lido:objectClassificationWrap/lido:classificationWrap/lido:classification/lido:term') { |x|
    s = x.text
  }
  solrjson["collection_within_repository"] = s if s.length > 0

  solrjson = JSON.pretty_generate(solrjson)
  puts solrjson
}
#0.050000   0.000000   0.050000 (  0.044453)