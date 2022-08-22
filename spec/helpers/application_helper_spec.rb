require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  #rspec ./spec/helpers/application_helper_spec.rb:6
  describe "#get_export_url_xml" do

    let(:solrdoc) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read))
    end

    let(:solrdoc2) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/dort.json","rb").read))
    end

    it "is a solrdoc" do
      expect(solrdoc).to be_an_instance_of SolrDocument
      expect(solrdoc2).to be_an_instance_of SolrDocument
      #NOTE using send as method is private
      #however there is error:
      #NoMethodError:
      #    undefined method `http://collections.britishart.yale.edu/oaicatmuseum/OAIHandler?verb=GetRecord&identifier=oai:tms.ycba.yale.edu:5005&metadataPrefix=lido' for #<#<Class:0x007fbfdd3cb730>:0x007fbfdd3b59a8>
      #expect(helper.send(get_export_url_xml(solrdoc2)).to_s).to be == "url"
    end
  end

  describe "parse linked_citation_ss" do
    it "lc1" do
      lc_ss = Array.new
      lc_ss.append("^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a4205451|b39116338|cND1354.4 Y25 1998 (YCBA)")
      lc_ss.append("^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a4205451|b39116338|cND1354.4 Y25 1998 (LC)")
      lc_ss.append("^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a|b39116338|cND1354.4 Y25 1998 (YCBA)")
      lc_ss.append("^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a4205451|b|cND1354.4 Y25 1998 (YCBA)")
      lc_ss.append("^Canaletto to Constable, paintings of town and country from the Yale Center for British Art ^, Yale Center for British Art, New Haven, Conn., 1998, pp. 5, 28, pl. 2, ND1354.4 Y25 1998 (YCBA)|a|b|c")

      expect(lc_ss.length).to eq 5

      expect(lc_ss).to be_an_instance_of Array

      lc_ss.each_with_index { |lc_ss1, index|
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
        #puts citation
        #puts ils
        #puts oclc
        #puts callnum
        result = ""
        if callnum.include?("(YCBA)") && ils.length > 0
          result =  "get BL"
        elsif ils.length > 0
          result = "get orbis"
        elsif oclc.length > 0
          result =  "get oclc"
        else
          result = "no link"
        end
        expect(result).to be == "get BL" if index == 0
        expect(result).to be == "get orbis" if index == 1
        expect(result).to be == "get oclc" if index == 2
        expect(result).to be == "get BL" if index == 3
        expect(result).to be == "no link" if index == 4
      }
    end
  end
end
