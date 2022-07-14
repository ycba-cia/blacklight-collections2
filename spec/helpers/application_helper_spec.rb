require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  #rspec ./spec/helpers/application_helper_spec.rb:6
  describe "#get_export_url_xml" do

    let(:solrdoc) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/leighton.json","rb").read))
    end

    let(:solrdoc2) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/prue.json","rb").read))
    end

    it "returns url" do
      #NOTE using send as method is private
      #however there is error:
      #NoMethodError:
      #    undefined method `http://collections.britishart.yale.edu/oaicatmuseum/OAIHandler?verb=GetRecord&identifier=oai:tms.ycba.yale.edu:5005&metadataPrefix=lido' for #<#<Class:0x007fbfdd3cb730>:0x007fbfdd3b59a8>
      #expect(helper.send(get_export_url_xml(solrdoc2)).to_s).to be == "url"
    end
  end

  describe "parse linked_citation_ss" do
    it "lc1" do
      lc_ss = ["^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a4205451|b39116338|cND1354.4 Y25 1998 (YCBA)",
               "^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a4205451|b39116338|cND1354.4 Y25 1998 (LC)",
               "^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a|b39116338|cND1354.4 Y25 1998 (YCBA)",
               "^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a4205451|b|cND1354.4 Y25 1998 (YCBA)",
               "^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a|b|c"]

      lc_ss.each { |lc_ss1|
        lc_ss1_split = lc_ss1.split("|")
        citation = ""
        ils = ""
        oclc = ""
        callnum = ""
        lc_ss1_split.each_with_index { |v,i|
          if i == 0
            citation = v
          else
            if v.starts_with?("a")
              ils = v[1..-1]
            elsif v.starts_with?("b")
              oclc = v[1..-1]
            elsif v.starts_with?("c")
              callnum = v[1..-1]
            end
          end
        }
        puts citation
        puts ils
        puts oclc
        puts callnum
        if callnum.include?("(YCBA)") && ils.length > 0
          puts "get BL"
        elsif ils.length > 0
          puts "get orbis"
        elsif oclc.length > 0
          puts "get oclc"
        else
          puts "no link"
        end
      }
    end
  end
end
