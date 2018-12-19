#run script from project root as below
#rails runner scripts/vu_bl_mapping_script.rb
#https://collections.britishart.yale.edu/vufind/Record/1669236
#get 'vufind/Record/:vufind_id' => 'vufind#show'
#localhost:3000/vufind/Record/1671909


require 'csv'

scripts = ["scripts/lido.csv","scripts/marc.csv"]

scripts.each do |type|
  CSV.foreach(type).with_index do |row, i|
    next if i == 0
    #break if i > 10
    vufind_id = row[0].to_s.split(" ")[0]
    oai_id = row[0].to_s.split(" ")[1]
    puts "#{vufind_id}-#{oai_id}"
    i = InterfaceMapping.new
    i.vufind_id = vufind_id
    i.oai_id = oai_id
    i.save
  end
end
