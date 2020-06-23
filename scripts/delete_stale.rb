require 'json'
require 'rsolr'

#june 23 2020
#"fl": "id, title_ss, author_ss,collection_ss,timestamp_dt",
#"fq": "-timestamp_dt:[NOW-1DAY TO NOW]",
#"sort": "timestamp_dt desc",
#"rows": "218"



file_str = "/Users/ermadmix/Google Drive/ycba/cia/to_delete_jun22_2020.json"
solr1 = RSolr.connect :url => "http://10.5.96.187:8983/solr/ycba-collections_dev1"
solr2 = RSolr.connect :url => "http://10.5.96.78:8983/solr/ycba_blacklight"
solr3 = RSolr.connect :url => "http://10.5.96.78:8983/solr/ycba_blacklight_prod"


file = File.read(file_str)
hash = JSON.parse(file)
count = 0
hash["response"]["docs"].each do |d|
  #break if count > 0 #to test
  count += 1
  puts d["id"]

  solr1.delete_by_id d["id"]
  solr2.delete_by_id d["id"]
  solr3.delete_by_id d["id"]
end

solr1.commit
solr2.commit
solr3.commit
solr1.optimize
solr2.optimize
solr3.optimize

puts "count: #{count}"