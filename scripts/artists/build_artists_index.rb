require 'tiny_tds'
require 'yaml'
require 'pp'
require 'time'
require 'rsolr'

start = Time.now
puts "Start: #{Time.now}"

y = YAML.load_file("../../config/local_env.yml")
#
tmshost = "172.18.56.252"
tmsuser = "s_ycba_imaging"
tmspw = y["TMSPROD"]
tmsdb = "TMS"
@tmsclient = TinyTds::Client.new(:username => tmsuser,
                                :password => tmspw,:host => tmshost,:database => tmsdb)
puts "tms client active:#{@tmsclient.active?}"

def getAuthorities(conID)
  altNum = Array.new
  altNumDesc = Array.new
  q = "select distinct a.ConstituentID, b.Altnum,c.AltNumDescription " +
      "from Constituents a " +
      "join altnums b on a.constituentID=b.ID " +
      "join AltNumDescriptions c on b.AltNumDescriptionID = c.AltNumDescriptionID " +
      "where a.ConstituentID = #{conID}"
  s = @tmsclient.execute(q)
  s.each do |row|
    altNum.push(row["Altnum"])
    altNumDesc.push(row["AltNumDescription"])
  end
  s.cancel
  return altNum,altNumDesc
end

test = "top 50"
objNums = Array.new
obj = Hash.new
objDetails = Hash.new
q = "select distinct #{test} a.ConstituentID, a.DisplayName, a.AlphaSort, a.Nationality,a.BeginDate,a.EndDate,a.Biography,a.Remarks " +
  "from Constituents a " +
  "join vConXrefs_Classic b on a.ConstituentID = b.ConstituentID " +
  "where a.ConstituentTypeID = 1 and b.RoleID = 1 " +
  "order by a.ConstituentID"
s = @tmsclient.execute(q)
s.each do |row|
  objDetails = Hash.new
  objDetails[:displayName_s] = row["DisplayName"]
  objDetails[:nationality_s] = row["Nationality"]
  objDetails[:alphaSort_s] = row["AlphaSort"]
  objDetails[:beginDate_i] = row["BeginDate"]
  objDetails[:endDate_i] = row["EndDate"]
  objDetails[:biography_s] = row["Biography"]
  objDetails[:remarks_s] = row["Remarks"]
  obj[row["ConstituentID"]] = objDetails
  objNums.push(row["ConstituentID"])
end
s.cancel

solr = RSolr.connect :url => "http://10.5.96.187:8983/solr/ycba-collections_dev1"

objNums.each do |o|
  altNum,altNumDesc = getAuthorities(o)
  obj1 = obj[o]
  #todo - method to merge in individual authorities
  obj1.merge!(:authorities_ss => altNum, :authoritiesLabel_ss => altNumDesc, :id => "artist:#{o}",:recordtype_ss =>"artists",
      :timestamp_dt => Time.now.utc.iso8601)
  puts "-----"
  pp(obj1)
  solr.add obj1
end

solr.commit
@tmsclient.close
