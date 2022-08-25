require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  #rspec ./spec/helpers/application_helper_spec.rb:11

  let(:document1) do
    JSON.parse(File.open("spec/fixtures/dort.json","rb").read)
  end

  let(:document2) do
    JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read)
  end

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

  describe "#render_as_link" do
    it "returns true" do
      options = Hash.new
      options[:value] = ["https://collections.britishart.yale.edu/catalog/tms:34"]
      expect(helper.render_as_link(options)).to be == "<a target=\"_blank\" href=\"https://collections.britishart.yale.edu/catalog/tms:34\">https://collections.britishart.yale.edu/catalog/tms:34</a>"
    end
  end

  describe "#render_aeon_from_access" do
    it "returns true" do
      options = Hash.new
      options[:value] = ["On view in the galleries"]
      options[:document] = document1
      expect(helper.render_aeon_from_access(options)).to be == "On view in the galleries"

      options[:value] = ["View by request in the Study Room"]
      options[:document][:detailed_onview_ss] = ["View by request in the Study Room"]
      expect(helper.render_aeon_from_access(options)).to be == "View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=B1977.14.77&ItemTitle=Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed&ItemAuthor=Joseph Mallord William Turner, 1775–1851, British&ItemDate=1818&Format=Support (PTG): 62 × 92 inches (157.5 × 233.7 cm)&Location=&mfhdID=&EADNumber=https://collections.britishart.yale.edu/catalog/tms:34' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"


      options[:value] = ["Accessible in the Reference Library"]
      options[:document][:detailed_onview_ss] = ["Accessible in the Reference Library"]
      expect(helper.render_aeon_from_access(options)).to be == "Accessible in the Reference Library [<a target=\"_blank\" href=\"https://britishart.yale.edu/about-us/departments/reference-library-and-archives\">Hours</a>]<br/><i>Note: The Reference Library is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/reference-library-and-photograph-archives\">Reference Library page</a> on our website for more details. For scans from the reference collection please email <a href=\"mailto:ycba.reference@yale.edu\">ycba.reference@yale.edu</a>.</i>"

    end
  end

  describe "#get_mfhd_base" do
    it "returns true" do
      expect(helper.get_mfhd_base).to be == "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid="
    end
  end

  describe "#pull_mfhd_doc" do
    it "returns true" do
      expect(helper.pull_mfhd_doc(document2.deep_symbolize_keys)).to be_an_instance_of Nokogiri::HTML4::Document
    end
  end

  describe "#get_mfhd_doc" do
    it "returns true" do
      expect(helper.get_mfhd_doc(document2.deep_symbolize_keys)).to be_an_instance_of Nokogiri::HTML4::Document

      allow(helper).to receive(:pull_mfhd_doc) do
        raise "boom"
      end
      expect(helper.get_mfhd_doc(document2.deep_symbolize_keys)).to be == "<span>Unable to reach service.  Holdings currently not available<span></br>"
    end
  end

  describe "#get_holdings" do
    it "returns true" do
      expect(helper.get_holdings(document2.deep_symbolize_keys)).to be == "<span>Rare Books and Manuscripts</span></br><span>Folio C 2014 4</span></br><span>Yale Center for British Art, Paul Mellon Collection</span></br><span>View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=Folio C 2014 4&ItemTitle=&ItemAuthor=&ItemDate=&Format=&Location=&mfhdID=9799201&EADNumber=' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i></span></br>"
    end
  end

  describe "#get_holdings2" do
    it "returns true" do
      expect(helper.get_holdings(document1.deep_symbolize_keys)).to be == "<span>Paintings and Sculpture</span></br><span>Not Available<span></br>"
    end
  end

  describe "#get_holdings3" do
    it "returns true" do
      allow(helper).to receive(:get_mfhd_doc) do
        raise "boom"
      end
      expect(helper.get_holdings(document1.deep_symbolize_keys)).to be == "<span>Unable to reach service.  Holdings currently not available<span></br>"
    end
  end


end
