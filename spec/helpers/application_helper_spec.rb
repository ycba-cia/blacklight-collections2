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

  let(:document3) do
    JSON.parse(File.open("spec/fixtures/dort_frame.json","rb").read)
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

  describe "#render_aeon_from_access_callnumber" do
    it "returns true" do
      expect(helper.render_aeon_from_access_callnumber(document2.deep_symbolize_keys,"bacrb","Folio C 2014 4",9799201)). to be == "View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=Folio C 2014 4&ItemTitle=&ItemAuthor=&ItemDate=&Format=&Location=&mfhdID=9799201&EADNumber=' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"
      expect(helper.render_aeon_from_access_callnumber(document2.deep_symbolize_keys,"bacref","Folio C 2014 4",9799201)). to be == "Accessible in the Reference Library [<a target=\"_blank\" href=\"https://britishart.yale.edu/about-us/departments/reference-library-and-archives\">Hours</a>]<br/><i>Note: The Reference Library is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/reference-library-and-photograph-archives\">Reference Library page</a> on our website for more details. For scans from the reference collection please email <a href=\"mailto:ycba.reference@yale.edu\">ycba.reference@yale.edu</a>.</i>"
      expect(helper.render_aeon_from_access_callnumber(document2.deep_symbolize_keys,"bacia","Folio C 2014 4",9799201)). to be == "Accessible by appointment in the Study Room [<a href=\"mailto:ycba.institutionalarchives@yale.edu\">Email</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"
    end
  end

  describe "#sort_values_and_link_to_facet" do
    it "returns true" do
      options = Hash.new
      options[:value] = ["Rotterdam", "Dordrecht", "Our Dear Lady Church", "Netherlands", "Dordrecht, Gemeente", "Noord"]
      expect(helper.sort_values_and_link_to_facet(options)).to be == "<a href=\"/?f[][]=Dordrecht\">Dordrecht</a> | <a href=\"/?f[][]=Dordrecht, Gemeente\">Dordrecht, Gemeente</a> | <a href=\"/?f[][]=Netherlands\">Netherlands</a> | <a href=\"/?f[][]=Noord\">Noord</a> | <a href=\"/?f[][]=Our Dear Lady Church\">Our Dear Lady Church</a> | <a href=\"/?f[][]=Rotterdam\">Rotterdam</a>"
    end
  end

  describe "#sort_values_and_link_to_facet_frames" do
    it "returns true" do
      options = Hash.new
      options[:document] = document1.deep_symbolize_keys
      options[:value] = ["marine art", "crowd", "sea", "church", "costume", "jars", "ship", "ships", "market (event)", "sunlight", "men", "women", "cityscape", "flags", "seascape", "rowboats", "fruit", "rubbish", "reflection", "chromaticity", "river", "city", "flotsam", "vegetables"]
      expect(helper.sort_values_and_link_to_facet_frames(options)).to be == "<a href=\"/?f[][]=chromaticity\">chromaticity</a> | <a href=\"/?f[][]=church\">church</a> | <a href=\"/?f[][]=city\">city</a> | <a href=\"/?f[][]=cityscape\">cityscape</a> | <a href=\"/?f[][]=costume\">costume</a> | <a href=\"/?f[][]=crowd\">crowd</a> | <a href=\"/?f[][]=flags\">flags</a> | <a href=\"/?f[][]=flotsam\">flotsam</a> | <a href=\"/?f[][]=fruit\">fruit</a> | <a href=\"/?f[][]=jars\">jars</a> | <a href=\"/?f[][]=marine art\">marine art</a> | <a href=\"/?f[][]=market (event)\">market (event)</a> | <a href=\"/?f[][]=men\">men</a> | <a href=\"/?f[][]=reflection\">reflection</a> | <a href=\"/?f[][]=river\">river</a> | <a href=\"/?f[][]=rowboats\">rowboats</a> | <a href=\"/?f[][]=rubbish\">rubbish</a> | <a href=\"/?f[][]=sea\">sea</a> | <a href=\"/?f[][]=seascape\">seascape</a> | <a href=\"/?f[][]=ship\">ship</a> | <a href=\"/?f[][]=ships\">ships</a> | <a href=\"/?f[][]=sunlight\">sunlight</a> | <a href=\"/?f[][]=vegetables\">vegetables</a> | <a href=\"/?f[][]=women\">women</a>"

      options = Hash.new
      options[:document] = document3.deep_symbolize_keys
      options[:value] = ["frame ornament: Leaf back; centred ribbon-&-stave; centred husk sight", "frame status: Possibly original", "frame cross-section: Concave", "frame style: 'Carlo Maratta' - NeoClassical variant", "frame alteration: probably not", "frame quality: Average"]
      expect(helper.sort_values_and_link_to_facet_frames(options)).to be == "<a href=\"/?f[][]=frame style: 'Carlo Maratta' - NeoClassical variant\">frame style: 'Carlo Maratta' - NeoClassical variant</a> | <a href=\"/?f[][]=frame status: Possibly original\">frame status: Possibly original</a> | <a href=\"/?f[][]=frame quality: Average\">frame quality: Average</a> | <a href=\"/?f[][]=frame ornament: Leaf back%3B centred ribbon-%26-stave%3B centred husk sight\">frame ornament: Leaf back; centred ribbon-&-stave; centred husk sight</a> | <a href=\"/?f[][]=frame cross-section: Concave\">frame cross-section: Concave</a> | <a href=\"/?f[][]=frame alteration: probably not\">frame alteration: probably not</a>"
    end
  end

  describe "#capitalize" do
    it "returns true" do
      options = Hash.new
      options = "available"
      expect(helper.capitalize(options)).to be == "Available"
    end
  end

  describe "#sort_values_and_link_to_topic_no_pipes" do
    it "returns true" do
      options = Hash.new
      options[:value] = [
          "Tollemache family.",
          "Bodleian Library. Manuscript. Ashmole 1504.",
          "Helmingham Hall.",
          "Agnus castus (Middle English herbal)",
          "Hortus sanitatis.",
          "Animals, Mythical, in art.",
          "Animals in art.",
          "Animals -- Folklore.",
          "Plants in art.",
          "Decoration and ornament -- England.",
          "Interior decoration -- England."
      ]
      expect(helper.sort_values_and_link_to_topic_no_pipes(options)).to be == "<a href=\"/?f[topic_ss][]=Agnus castus (Middle English herbal)\">Agnus castus (Middle English herbal)</a></br><a href=\"/?f[topic_ss][]=Animals -- Folklore.\">Animals -- Folklore.</a></br><a href=\"/?f[topic_ss][]=Animals in art.\">Animals in art.</a></br><a href=\"/?f[topic_ss][]=Animals, Mythical, in art.\">Animals, Mythical, in art.</a></br><a href=\"/?f[topic_ss][]=Bodleian Library. Manuscript. Ashmole 1504.\">Bodleian Library. Manuscript. Ashmole 1504.</a></br><a href=\"/?f[topic_ss][]=Decoration and ornament -- England.\">Decoration and ornament -- England.</a></br><a href=\"/?f[topic_ss][]=Helmingham Hall.\">Helmingham Hall.</a></br><a href=\"/?f[topic_ss][]=Hortus sanitatis.\">Hortus sanitatis.</a></br><a href=\"/?f[topic_ss][]=Interior decoration -- England.\">Interior decoration -- England.</a></br><a href=\"/?f[topic_ss][]=Plants in art.\">Plants in art.</a></br><a href=\"/?f[topic_ss][]=Tollemache family.\">Tollemache family.</a>"
    end
  end

  describe "#sort_values_and_link_to_topic" do
    it "returns true" do
      options = Hash.new
      options[:value] = [
          "Tollemache family.",
          "Bodleian Library. Manuscript. Ashmole 1504.",
          "Helmingham Hall.",
          "Agnus castus (Middle English herbal)",
          "Hortus sanitatis.",
          "Animals, Mythical, in art.",
          "Animals in art.",
          "Animals -- Folklore.",
          "Plants in art.",
          "Decoration and ornament -- England.",
          "Interior decoration -- England."
      ]
      expect(helper.sort_values_and_link_to_topic(options)).to be == "<a href=\"/?f[topic_ss][]=Agnus castus (Middle English herbal)\">Agnus castus (Middle English herbal)</a> | </br><a href=\"/?f[topic_ss][]=Animals -- Folklore.\">Animals -- Folklore.</a> | </br><a href=\"/?f[topic_ss][]=Animals in art.\">Animals in art.</a> | </br><a href=\"/?f[topic_ss][]=Animals, Mythical, in art.\">Animals, Mythical, in art.</a> | </br><a href=\"/?f[topic_ss][]=Bodleian Library. Manuscript. Ashmole 1504.\">Bodleian Library. Manuscript. Ashmole 1504.</a> | </br><a href=\"/?f[topic_ss][]=Decoration and ornament -- England.\">Decoration and ornament -- England.</a> | </br><a href=\"/?f[topic_ss][]=Helmingham Hall.\">Helmingham Hall.</a> | </br><a href=\"/?f[topic_ss][]=Hortus sanitatis.\">Hortus sanitatis.</a> | </br><a href=\"/?f[topic_ss][]=Interior decoration -- England.\">Interior decoration -- England.</a> | </br><a href=\"/?f[topic_ss][]=Plants in art.\">Plants in art.</a> | </br><a href=\"/?f[topic_ss][]=Tollemache family.\">Tollemache family.</a>"
    end
  end



end
