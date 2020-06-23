require 'rsolr'

sources = ["lido","marc"]
#sources = ["marc"] #test one source


#@solr = RSolr.connect :url => "http://discover.odai.yale.edu/vufind-solr/biblio"

#ssh -L 8380:vm-odaiprd-01.its.yale.edu:8380 bac6-dev.its.yale.edu -l ermadmix
@solr = RSolr.connect :url => "http://localhost:8380/solr/biblio"

def process_lido
  start = 0
  stop = false
  pagelength = 200
  list = []
  list.push("vufind_id oai_harvester_id")
  while stop == false
    response = @solr.post 'select', :params => {
        :q=>'institution_facet:"Yale Center for British Art". && recordtype:"lido"',
        :sort=>'id asc',
        :start=>start,
        :rows=>pagelength
    }
    stop = true if response['response']['docs'].length == 0
    #stop = true if start > 20 #for testing
    response["response"]["docs"].each { |doc|
      vufindid = doc["id"]
      tmsid = "oai:tms.ycba.yale.edu:" + doc["cds_object_id"]
      line = vufindid + " " + tmsid
      list.push(line)
    }
    start +=pagelength
    puts start
  end
  File.open("lido3.csv", "w+") do |f|
    list.each { |line| f.puts(line) }
  end
end

def process_marc
  start = 0
  stop = false
  pagelength = 200
  list = []
  list.push("vufind_id oai_harvester_id")
  while stop == false
    response = @solr.post 'select', :params => {
        :q=>'institution_facet:"Yale Center for British Art". && recordtype:"marc"',
        :sort=>'id asc',
        :start=>start,
        :rows=>pagelength
    }
    stop = true if response['response']['docs'].length == 0
    #stop = true if start > 20 #for testing
    response["response"]["docs"].each { |doc|
      vufindid = doc["id"]
      tmsid = "oai:orbis.library.yale.edu:" + doc["url"].split("/")[5]
      line = vufindid + " " + tmsid
      list.push(line)
    }
    start +=pagelength
    puts start
  end
  File.open("marc3.csv", "w+") do |f|
    list.each { |line| f.puts(line) }
  end
end



sources.each { |type|
  puts type
  if type=="lido"
    process_lido
  end
  if type=="marc"
    process_marc
  end
}