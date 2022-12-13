require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  #rspec ./spec/helpers/application_helper_spec.rb:11
  #note: to improve, next https stubs so not calling repeatedly

  let(:document1) do
    JSON.parse(File.open("spec/fixtures/dort.json","rb").read)
  end

  let(:document2) do
    JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read)
  end

  let(:document3) do
    JSON.parse(File.open("spec/fixtures/dort_frame.json","rb").read)
  end

  let(:document4) do
    JSON.parse(File.open("spec/fixtures/smith.json","rb").read)
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

  describe "#handle qualifiers" do
    it "returns true" do
      options = Hash.new
      options[:value] = ["John Nost I, before 1660–1711/1712, Flemish, active in Britain (from before 1686)","or John Cheere, 1709–1787, British"]
      options[:document] = {}
      options[:document][:author_removed_ss] = ["John Nost I, before 1660–1711/1712, Flemish, active in Britain (from before 1686)","John Cheere, 1709–1787, British"]
      expect(helper.handle_qualifiers(options)).to be == "<a href=\"/?f[author_removed_ss][]=John Nost I, before 1660–1711/1712, Flemish, active in Britain (from before 1686)\">John Nost I, before 1660–1711/1712, Flemish, active in Britain (from before 1686)</a><br/><a href=\"/?f[author_removed_ss][]=John Cheere, 1709–1787, British\">or John Cheere, 1709–1787, British</a>"
    end
  end

  describe "#render_aeon_from_access" do
    it "returns true" do
      #ps
      options = Hash.new
      options[:value] = ["On view in the galleries"]
      options[:document] = document1
      expect(helper.render_aeon_from_access(options)).to be == "On view in the galleries"

      #rb
      options[:value] = ["View by request in the Study Room"]
      options[:document] = document2
      options[:document][:detailed_onview_ss] = ["View by request in the Study Room"]
      #expect(helper.render_aeon_from_access(options)).to be == "View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=&ItemTitle=Helmingham herbal and bestiary.&ItemAuthor=&ItemDate=1500&Format=1 v. ([20] leaves, with 1 blank leaf) : ill. ; 45 x 32 cm.&Location=bacrb&mfhdID=9799201&EADNumber=http://hdl.handle.net/10079/bibid/9452785' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"
      stub_request(:get, "https://libapp-test.library.yale.edu/VoySearch/GetBibItem?bibid=9452785").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'Host'=>'libapp-test.library.yale.edu',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_bibitem.json')), headers: {})
      expect(helper.render_aeon_from_access(options)).to be == "View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=&ItemTitle=Helmingham herbal and bestiary.&ItemAuthor=&ItemDate=1500&Format=1 v. ([20] leaves, with 1 blank leaf) : ill. ; 45 x 32 cm.&Location=bacrb&mfhdID=9799201&EADNumber=http://hdl.handle.net/10079/bibid/9452785' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"


      #ref
      #possible to do, need to mock full ref doc?
      options[:value] = ["Accessible in the Reference Library"]
      options[:document][:detailed_onview_ss] = ["Accessible in the Reference Library"]
      expect(helper.render_aeon_from_access(options)).to be == "Accessible in the Reference Library [<a target=\"_blank\" href=\"https://britishart.yale.edu/about-us/departments/reference-library-and-archives\">Hours</a>]<br/><i>Note: The Reference Library is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/reference-library-and-photograph-archives\">Reference Library page</a> on our website for more details. For scans from the reference collection please email <a href=\"mailto:ycba.reference@yale.edu\">ycba.reference@yale.edu</a>.</i>"

      #pd
      options[:value] = ["View by request in the Study Room"]
      options[:document] = document4
      options[:document][:detailed_onview_ss] = ["View by request in the Study Room"]
      expect(helper.render_aeon_from_access(options)).to be == "View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestPD&Site=YCBA&CallNumber=B1977.14.7220&ItemTitle=Hannibal passing the Alps (vignette)&ItemAuthor=Print made by W. R. Smith, active 1819–1851&ItemDate=1830&Format=Etching and line engraving; engraver's proof on medium, slightly textured, cream wove paper&Location=bacpd&mfhdID=&EADNumber=https://collections.britishart.yale.edu/catalog/tms:16950' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i>"
    end
  end

  describe "#get_mfhd_base" do
    it "returns true" do
      expect(helper.get_mfhd_base).to be == "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid="
    end
  end

  describe "#pull_mfhd_doc" do
    it "returns true" do
      stub_request(:get, "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid=9452785").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_mfhd.xml')), headers: {})
      expect(helper.pull_mfhd_doc(document2.deep_symbolize_keys)).to be_an_instance_of Nokogiri::HTML4::Document
    end
  end

  describe "#get_mfhd_doc" do
    it "returns true" do

      stub_request(:get, "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid=9452785").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_mfhd.xml')), headers: {})
      expect(helper.get_mfhd_doc(document2.deep_symbolize_keys)).to be_an_instance_of Nokogiri::HTML4::Document

      allow(helper).to receive(:pull_mfhd_doc) do
        raise "boom"
      end
      expect(helper.get_mfhd_doc(document2.deep_symbolize_keys)).to be == "<span>Unable to reach service.  Holdings currently not available<span></br>"
    end
  end

  describe "#get_holdings" do
    it "returns true" do
      stub_request(:get, "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid=9452785").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_mfhd.xml')), headers: {})
      expect(helper.get_holdings(document2.deep_symbolize_keys)).to be == "<span>Rare Books and Manuscripts</span></br><span>Folio C 2014 4</span></br><span>Yale Center for British Art, Paul Mellon Collection</span></br><span>View by request in the Study Room [<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=Folio C 2014 4&ItemTitle=&ItemAuthor=&ItemDate=&Format=&Location=&mfhdID=9799201&EADNumber=' target='_blank'>Request</a>]<br/><i>Note: The Study Room is open by appointment. Please visit the <a href=\"https://britishart.yale.edu/study-room\">Study Room page</a> on our website for more details.</i></span></br>"
    end
  end

  describe "#get_holdings2" do
    it "returns true" do
      stub_request(:get, "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid=34").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_mfhd.xml')), headers: {})
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

  describe "#link_to_author" do
    it "returns true" do
      options = Hash.new
      options[:document] = {}
      options[:document][:auth_author_display_ss] = ["Ireland, Samuel, -1800."]
      options[:value] = ["Ireland, Samuel, -1800"]
      expect(helper.link_to_author(options)).to be == "<a href=\"/?f[author_ss][]=Ireland, Samuel, -1800\">Ireland, Samuel, -1800.</a>"
    end
  end

  describe "#render_related_content" do
    it "returns true" do
      options = Hash.new
      options[:value] = ["View finding aid for the Roger W. Moss Collection of manuscript, original art and printed material by and about Richard Shirley Smith\nhttp://hdl.handle.net/10079/fa/ycba.mss.0017"]
      expect(helper.render_related_content(options)).to be == "<a target=\"_blank\" href=\"http://hdl.handle.net/10079/fa/ycba.mss.0017\">View finding aid for the Roger W. Moss Collection of manuscript, original art and printed material by and about Richard Shirley Smith</a>"

      options = Hash.new
      options[:value] = ["\nhttps://nal-vam.on.worldcat.org/oclc/1008577166"]
      expect(helper.render_related_content(options)).to be == "<a target=\"_blank\" href=\"https://nal-vam.on.worldcat.org/oclc/1008577166\">https://nal-vam.on.worldcat.org/oclc/1008577166</a>"

      options = Hash.new
      options[:value] = ["https://nal-vam.on.worldcat.org/oclc/1008577166"]
      expect(helper.render_related_content(options)).to be == "https://nal-vam.on.worldcat.org/oclc/1008577166"
    end

    describe "#render_citation" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["Inscribed, lower right: \"Dort\"", "Signed and dated, lower right: \"JMW Turner RA 1818\""]
        options[:document] = document1.deep_symbolize_keys
        expect(helper.render_citation(options)).to be == "<p>Inscribed, lower right: \"Dort\"</p></i> <p>Signed and dated, lower right: \"JMW Turner RA 1818\"</p></i>"

        options[:document][:citation_sort_ss] = nil
        expect(helper.render_citation(options)).to be == "<p>Inscribed, lower right: \"Dort\"</p></i> <p>Signed and dated, lower right: \"JMW Turner RA 1818\"</p></i>"

        options[:document][:citation_sort_ss] = [nil]
        expect(helper.render_citation(options)).to be == "<p>Inscribed, lower right: \"Dort\"</p></i> <p>Signed and dated, lower right: \"JMW Turner RA 1818\"</p></i>"
      end
    end

    describe "#render_tms_citation_presorted" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["<i>'Splashers,' Scrawlers' and 'Plasterers' : British landscape painting and the language of criticism, 1800-40</i>, Mallord Press, London, Summer 1990, pp. 5-11, NJ18 T85 T87+ (YCBA)",
        "<i>[Yale University Press Advertisement ] Dort or Dordrecht:, The Dort Packed-boat from Rotterdam Becalmed </i>, Art Journal (CAA), 37, no. 1, Autumn 1977, p. 81, N81 A887 + OVERSIZE (HAAS) Available online in JSTOR"]
        options[:document] = {}
        options[:document][:citationURL_ss] = ["-","-"]
        expect(helper.render_tms_citation_presorted(options)).to be == "<p><i>'Splashers,' Scrawlers' and 'Plasterers' : British landscape painting and the language of criticism, 1800-40</i>, Mallord Press, London, Summer 1990, pp. 5-11, NJ18 T85 T87+ (YCBA)</i><p> <p><i>[Yale University Press Advertisement ] Dort or Dordrecht:, The Dort Packed-boat from Rotterdam Becalmed </i>, Art Journal (CAA), 37, no. 1, Autumn 1977, p. 81, N81 A887 + OVERSIZE (HAAS) Available online in JSTOR</i><p>"

        options[:document][:citationURL_ss] = ["https://test.yale.edu","-"]
        expect(helper.render_tms_citation_presorted(options)).to be == "<p><a target=\"_blank\" href=\"https://test.yale.edu\"><i>'Splashers,' Scrawlers' and 'Plasterers' : British landscape painting and the language of criticism, 1800-40</i>, Mallord Press, London, Summer 1990, pp. 5-11, NJ18 T85 T87+ (YCBA)</i></a></p> <p><i>[Yale University Press Advertisement ] Dort or Dordrecht:, The Dort Packed-boat from Rotterdam Becalmed </i>, Art Journal (CAA), 37, no. 1, Autumn 1977, p. 81, N81 A887 + OVERSIZE (HAAS) Available online in JSTOR</i><p>"
      end
    end

    describe "#render_marc_citation_presorted_tab" do
      it "returns true" do
        document = Hash.new
        document["citation_ss"] = ["Citation1","Citation2"]
        document["citationURL_ss"] = ["-","-"]
        expect(helper.render_marc_citation_presorted_tab(document)).to be == "<p>Citation1</i><p> <p>Citation2</i><p>"

        document["citationURL_ss"] = ["https://test.yale.edu","-"]
        expect(helper.render_marc_citation_presorted_tab(document)).to be == "<p><a target=\"_blank\" href=\"https://test.yale.edu\">Citation1</i></a></p> <p>Citation2</i><p>"
      end
    end

    describe "#render_lido_citation_presorted_tab" do
      it "returns true" do
        document = Hash.new
        document["linked_citation_ss"] = ["Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)|a584227|b7605713|cNJ18 T85 T87 + (YCBA)"]
        document["citationURL_ss"] = ["-"]
        #puts helper.render_lido_citation_presorted_tab(document)
        expect(helper.render_lido_citation_presorted_tab(document)).to be == "<p>Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)</i> [<a target=\"_blank\" href=\"https://collections.britishart.yale.edu/catalog/orbis:584227\">YCBA</a>]</p>"

        document["linked_citation_ss"] = ["Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)||b7605713|cNJ18 T85 T87 + (YCBA)"]
        #puts helper.render_lido_citation_presorted_tab(document)
        expect(helper.render_lido_citation_presorted_tab(document)).to be == "<p>Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)</i> [<a target=\"_blank\" href=\"http://www.worldcat.org/oclc/7605713\">OCLC</a>]</p>"

        document["linked_citation_ss"] = ["Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)|||cNJ18 T85 T87 + (YCBA)"]
        #puts helper.render_lido_citation_presorted_tab(document)
        expect(helper.render_lido_citation_presorted_tab(document)).to be == "<p>Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)</i></p>"

        document["linked_citation_ss"] = ["Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)|a584227|b7605713|"]
        #puts helper.render_lido_citation_presorted_tab(document)
        expect(helper.render_lido_citation_presorted_tab(document)).to be == "<p>Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)</i> [<a target=\"_blank\" href=\"https://hdl.handle.net/10079/bibid/584227\">ORBIS</a>]</p>"

        document["linked_citation_ss"] = ["Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)|a584227|b7605713|cNJ18 T85 T87 + (YCBA)"]
        document["citationURL_ss"] = ["https://test.yale.edu"]
        #puts helper.render_lido_citation_presorted_tab(document)
        expect(helper.render_lido_citation_presorted_tab(document)).to be == "<p>Alfred Gustave Herbert Bachrach, <i>The Field of Waterloo and Beyond</i>, Turner Studies, vol. 1, 1981, pp. 4-13, NJ18 T85 T87 + (YCBA)</i> [<a target=\"_blank\" href=\"https://test.yale.edu\">Website</a>]</p>"
      end
    end

    describe "#render_exhibitions" do
      it "returns true" do
        options = Hash.new
        options[:value] = [
            "Yale University Art Gallery 2015 - 2016 (Yale University Art Gallery, 2015-07-27 - 2015-01-05)",
            "The Critique of Reason : Romantic Art, 1760–1860 (Yale University Art Gallery, 2015-03-06 - 2015-07-26)",
            "An American's Passion for British Art - Paul Mellon's Legacy (Royal Academy of Arts, 2007-10-20 - 2008-01-27)"]
        expect(helper.render_exhibitions(options)).to be == "<p><a href=\"/?f[exhibition_history_ss][]=An+American%27s+Passion+for+British+Art+-+Paul+Mellon%27s+Legacy+%28Royal+Academy+of+Arts%2C+2007-10-20+-+2008-01-27%29\">An American's Passion for British Art - Paul Mellon's Legacy (Royal Academy of Arts, 2007-10-20 - 2008-01-27)</a></p><p><a href=\"/?f[exhibition_history_ss][]=The+Critique+of+Reason+%3A+Romantic+Art%2C+1760%E2%80%931860+%28Yale+University+Art+Gallery%2C+2015-03-06+-+2015-07-26%29\">The Critique of Reason : Romantic Art, 1760–1860 (Yale University Art Gallery, 2015-03-06 - 2015-07-26)</a></p><p><a href=\"/?f[exhibition_history_ss][]=Yale+University+Art+Gallery+2015+-+2016+%28Yale+University+Art+Gallery%2C+2015-07-27+-+2015-01-05%29\">Yale University Art Gallery 2015 - 2016 (Yale University Art Gallery, 2015-07-27 - 2015-01-05)</a></p>"
      end
    end

    describe "#render_exhibitions_tab" do
      it "returns true" do
        document = Hash.new
        document["exhibition_history_ss"] = [
            "Yale University Art Gallery 2015 - 2016 (Yale University Art Gallery, 2015-07-27 - 2015-01-05)",
            "The Critique of Reason : Romantic Art, 1760–1860 (Yale University Art Gallery, 2015-03-06 - 2015-07-26)",
            "An American's Passion for British Art - Paul Mellon's Legacy (Royal Academy of Arts, 2007-10-20 - 2008-01-27)"]
        expect(helper.render_exhibitions_tab(document)).to be == "<p>Yale University Art Gallery 2015 - 2016 (Yale University Art Gallery, 2015-07-27 - 2015-01-05) [<a href=\"/?f[exhibition_history_ss][]=Yale+University+Art+Gallery+2015+-+2016+%28Yale+University+Art+Gallery%2C+2015-07-27+-+2015-01-05%29\" target='_blank'>YCBA Objects in the Exhibition</a>]</p><p>The Critique of Reason : Romantic Art, 1760–1860 (Yale University Art Gallery, 2015-03-06 - 2015-07-26) [<a href=\"/?f[exhibition_history_ss][]=The+Critique+of+Reason+%3A+Romantic+Art%2C+1760%E2%80%931860+%28Yale+University+Art+Gallery%2C+2015-03-06+-+2015-07-26%29\" target='_blank'>YCBA Objects in the Exhibition</a>]</p><p>An American's Passion for British Art - Paul Mellon's Legacy (Royal Academy of Arts, 2007-10-20 - 2008-01-27) [<a href=\"/?f[exhibition_history_ss][]=An+American%27s+Passion+for+British+Art+-+Paul+Mellon%27s+Legacy+%28Royal+Academy+of+Arts%2C+2007-10-20+-+2008-01-27%29\" target='_blank'>YCBA Objects in the Exhibition</a>]</p>"

        document["exhibitionURL_ss"] = ["https://awesitelink.edu"]
        expect(helper.render_exhibitions_tab(document)).to be == "<p>Yale University Art Gallery 2015 - 2016 (Yale University Art Gallery, 2015-07-27 - 2015-01-05) [<a href=\"/?f[exhibition_history_ss][]=Yale+University+Art+Gallery+2015+-+2016+%28Yale+University+Art+Gallery%2C+2015-07-27+-+2015-01-05%29\" target='_blank'>YCBA Objects in the Exhibition</a>] [<a href=\"https://awesitelink.edu\" target='_blank'>Exhibition Description</a>]</p><p>The Critique of Reason : Romantic Art, 1760–1860 (Yale University Art Gallery, 2015-03-06 - 2015-07-26) [<a href=\"/?f[exhibition_history_ss][]=The+Critique+of+Reason+%3A+Romantic+Art%2C+1760%E2%80%931860+%28Yale+University+Art+Gallery%2C+2015-03-06+-+2015-07-26%29\" target='_blank'>YCBA Objects in the Exhibition</a>]</p><p>An American's Passion for British Art - Paul Mellon's Legacy (Royal Academy of Arts, 2007-10-20 - 2008-01-27) [<a href=\"/?f[exhibition_history_ss][]=An+American%27s+Passion+for+British+Art+-+Paul+Mellon%27s+Legacy+%28Royal+Academy+of+Arts%2C+2007-10-20+-+2008-01-27%29\" target='_blank'>YCBA Objects in the Exhibition</a>]</p>"
      end
    end

    describe "#render_parent" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["The Tempest"]
        expect(helper.render_parent(options)).to be == "<p><a href=\"/?f[title_collective_ss][]=The Tempest\">Collective Title: The Tempest</a></p>"
      end
    end

    describe "#render_titles_all" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed","Another Title"]
        expect(helper.render_titles_all(options)).to be == "<p>Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed</p><p>Another Title</p>"
      end
    end

    describe "#extract_date2" do
      it "returns true" do
        d = "\" Of Green Leaf, Bird, and Flower \" : Artists' Books and the Natural World (Yale Center for British Art, 2014-05-15 - 2014-08-10)"
        expect(helper.extract_date2(d)).to be == Date.parse("2014-05-15",limit: nil)
        d = "no date"
        expect(helper.extract_date2(d)).to be == Date.parse("9999-12-31",limit: nil)
        d = "An exhibit (Yale Center for British Art, August 31,2022 - September 1, 2022)"
        expect(helper.extract_date2(d)).to be == Date.parse("2022-08-31", limit: nil)
      end
    end

    describe "#extract_date" do
      it "returns true" do
        d = "An exhibit (Yale Center for British Art, August 31,2022 - September 1, 2022)"
        expect(helper.extract_date(d)).to be == Date.parse("2022-08-31", limit: nil)
      end
    end

    describe "#combine_topic_subject" do
      it "returns true" do
        options = Hash.new
        options[:document] = {}
        options[:document][:topic_subjectConcept_ss] = ["subjectconcept1"]
        options[:document][:topic_subjectEvent_ss] = ["subjectevent1"]
        options[:document][:topic_subjectObject_ss] = ["subjectobject1"]
        expect(helper.combine_topic_subject(options)).to be == "subjectconcept1 subjectevent1 subjectobject1"
      end
    end

    describe "#combine_curatorial_comments" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["One I have finished."]
        options[:document] = {}
        expect(helper.combine_curatorial_comments(options)).to be == "One I have finished.</br>"
        options[:document][:curatorial_comment_auth_ss] = ["Scott Wilcox"]
        options[:document][:curatorial_comment_date_ss] = ["2007-01"]
        expect(helper.combine_curatorial_comments(options)).to be == "One I have finished.</br>--Scott Wilcox,2007-01</br>"
      end
    end

    describe "#combine_curatorial_comments_tab" do
      it "returns true" do
        document = Hash.new
        document["curatorial_comment_ss"] = ["One I have finished."]
        expect(helper.combine_curatorial_comments_tab(document)).to be == ["One I have finished.</br>"]
        document["curatorial_comment_auth_ss"] = ["Scott Wilcox"]
        expect(helper.combine_curatorial_comments_tab(document)).to be == ["One I have finished.</br>--Scott Wilcox</br>"]
        document["curatorial_comment_date_ss"] = ["2007-01"]
        expect(helper.combine_curatorial_comments_tab(document)).to be == ["One I have finished.</br>--Scott Wilcox,2007-01</br>"]
      end
    end

    describe "#format_contents_tab" do
      it "returns true" do
        document = Hash.new
        document["marc_contents_ss"] = ["Alphabet: folio 1","Herbal: folio 2","Bestiary: folio 3"]
        expect(helper.format_contents_tab(document)).to be == "<ul style='list-style: disc; margin-left: 15px;'><li>Alphabet: folio 1</li><li>Herbal: folio 2</li><li>Bestiary: folio 3</li></ul>"
      end
    end

    describe "#render_search_per_line" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["https://one.edu","https://two.edu"]
        expect(helper.render_search_per_line(options)).to be == "<a href=\"https://one.edu\">https://one.edu</a><br/><a href=\"https://two.edu\">https://two.edu</a>"
      end
    end

    describe "#render_copyright_status" do
      it "returns true" do
        options = Hash.new
        options[:document] = {}
        expect(helper.render_copyright_status(options)).to be == "<a target=\"_blank\" rel=\"nofollow\" href=\"http://rightsstatements.org/vocab/CNE/1.0/\">Copyright Not Evaluated</a>"
        options[:document] = document1.deep_symbolize_keys
        expect(helper.render_copyright_status(options)).to be == "<a target=\"_blank\" rel=\"nofollow\" href=\"https://creativecommons.org/publicdomain/zero/1.0/\">Public Domain</a>"
      end
    end

    describe "#add_alt_publisher" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["publisher1","publisher2"]
        options[:document] = {}
        options[:document][:altrep_publisher_ss] = ["[Tokyo] : ラスキン展実行委員会, 1993."]
        expect(helper.add_alt_publisher(options)).to be == "publisher1<br/>publisher2<br/>[Tokyo] : ラスキン展実行委員会, 1993."
      end
    end

    describe "#add_alt_title" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["title1","title2"]
        options[:document] = {}
        options[:document][:altrep_title_ss] = ["リン・チャドウィック彫刻展　= Lynn Chadwick."]
        expect(helper.add_alt_title(options)).to be == "title1<br/>title2<br/>リン・チャドウィック彫刻展　= Lynn Chadwick."
      end
    end

    describe "#add_alt_title_alt" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["title1","title2"]
        options[:document] = {}
        options[:document][:altrep_title_alt_ss] = ["粉紅世界"]
        expect(helper.add_alt_title_alt(options)).to be == "title1<br/>title2<br/>粉紅世界"
      end
    end

    describe "#add_alt_edition" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["ed1","ed2"]
        options[:document] = {}
        options[:document][:altrep_edition_ss] = ["第1版."]
        expect(helper.add_alt_edition(options)).to be == "ed1<br/>ed2<br/>第1版."
      end
    end

    describe "#add_alt_description" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["desc1","desc2"]
        options[:document] = {}
        options[:document][:altrep_description_ss] = ["其他题名:Staging the world."]
        expect(helper.add_alt_description(options)).to be == "desc1<br/>desc2<br/>其他题名:Staging the world."
      end
    end

    describe "#cds_info_url" do
      it "returns true" do
        expect(helper.cds_info_url("34")).to be == "https://deliver.odai.yale.edu/info/repository/YCBA/object/34/type/2"
      end
    end

    describe "#cds_thumbnail_url" do
      it "returns true" do
        expect(helper.cds_thumbnail_url("34")).to be == "https://deliver.odai.yale.edu/content/repository/YCBA/object/34/type/2/format/1"
      end
    end

    describe "#display_rights" do
      it "returns true" do
        document = Hash.new
        expect(helper.display_rights(document)).to be == ""
        document["ort_ss"] = ["Public Domain"]
        expect(helper.display_rights(document)).to be == "Public Domain"
        document["rightsURL_ss"] = ["https://creativecommons.org/publicdomain/zero/1.0/"]
        expect(helper.display_rights(document)).to be == "<a target=\"_blank\" rel=\"nofollow\" href=\"https://creativecommons.org/publicdomain/zero/1.0/\">Public Domain</a>"
      end
    end

    describe "#image_request_link" do
      it "returns true" do
        stub_request(:get, "https://libapp.library.yale.edu/VoySearch/GetAllMfhdItem?bibid=9452785").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_mfhd.xml')), headers: {})
        document = document1.deep_symbolize_keys
        expect(helper.image_request_link(document)).to be == "https://britishart.yale.edu/request-images?id=34&num=B1977.14.77&collection=Paintings and Sculpture&creator=Joseph Mallord William Turner, 1775–1851, British&title=Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed&url=https://collections.britishart.yale.edu/catalog/tms:34"
        document = document2.deep_symbolize_keys
        expect(helper.image_request_link(document)).to be == "https://britishart.yale.edu/request-images-rare-books-and-manuscripts?id=9452785&num=Folio C 2014 4&collection=Rare Books and Manuscripts&creator=&title=Helmingham herbal and bestiary.&url=http://hdl.handle.net/10079/bibid/9452785"

        allow(helper).to receive(:get_mfhd_doc) do
          raise "boom"
        end
        expect(helper.image_request_link(document)).to be == "<span>Unable to reach service.  Holdings currently not available<span></br>"
      end
    end

    describe "#information_link_subject" do
      it "returns true" do
        document = document1.deep_symbolize_keys
        expect(helper.information_link_subject(document)).to be == "[Online Collection] B1977.14.77, Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed, Joseph Mallord William Turner, 1775–1851, British "
       end
    end

    describe "#information_link_subject_on_view" do
      it "returns true" do
        document = document1.deep_symbolize_keys
        expect(helper.information_link_subject_on_view(document)).to be == "[Onview Request] B1977.14.77, Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed, Joseph Mallord William Turner, 1775–1851, British "
      end
    end

    describe "#thumb" do
      it "returns true" do
        document = document1.deep_symbolize_keys
        options = Hash.new
        expect(helper.thumb(document,options)).to include "src=\"https://media.collections.yale.edu/thumbnail/ycba/4f227f08-7842-46cc-b05a-e3c6a4614cc1\""
        expect(helper.thumb(document,options)).to include "<img alt=\"Joseph Mallord William Turner Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed\""

        document[:recordtype_ss] = ["marc"]
        document[:isbn_ss] = ["12345678"]
        document[:collection_ss] = ["Reference Library"]
        expect(helper.thumb(document,options)).to include "src=\"/bookcover/isbn/12345678/size/medium\""
        expect(helper.thumb(document,options)).to include "<img alt=\"Joseph Mallord William Turner Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed\""

      end
    end

    describe "#doc_thumbnail" do
      it "returns true" do
        document = document1.deep_symbolize_keys
        expect(helper.doc_thumbnail(document)).to be == "https://media.collections.yale.edu/thumbnail/ycba/4f227f08-7842-46cc-b05a-e3c6a4614cc1"
      end
    end

    describe "#get_export_url_xml" do
      it "returns true" do
        document = document1.deep_symbolize_keys
        expect(helper.get_export_url_xml(document)).to be == "http://harvester-bl.britishart.yale.edu/oaicatmuseum/OAIHandler?verb=GetRecord&identifier=oai:tms.ycba.yale.edu:34&metadataPrefix=lido"
        document = document2.deep_symbolize_keys
        expect(helper.get_export_url_xml(document)).to be == "https://libapp.library.yale.edu/OAI_BAC/src/OAIOrbisTool.jsp?verb=GetRecord&identifier=oai:orbis.library.yale.edu:9452785&metadataPrefix=marc21"
      end
    end

    describe "#get_bib_from_handle" do
      it "returns true" do
        document = {}
        expect(helper.get_bib_from_handle(document)).to be == ""
        document[:url_ss] = ["https://hdl.handle.net/10079/bibid/123456"]
        expect(helper.get_bib_from_handle(document)).to be == "123456"
        document[:url_ss] = ["http://hdl.handle.net/10079/bibid/123456"]
        expect(helper.get_bib_from_handle(document)).to be == "123456"
      end
    end

    describe "#get_manifest_from_document" do
      it "returns true" do
        document = document1.deep_symbolize_keys
        expect(helper.get_manifest_from_document(document)).to be == "https://manifests.collections.yale.edu/ycba/obj/34"
        document = document2.deep_symbolize_keys
        expect(helper.get_manifest_from_document(document)).to be == "https://manifests.collections.yale.edu/ycba/orb/9452785"
      end
    end

    describe "#show_svg" do
      it "returns true" do
        v = "logo-horizontal.svg"
        #puts helper.show_svg(v)
        expect(helper.show_svg(v)).to include "<svg viewBox=\"0 0 611 18"
        expect(helper.show_svg(v)).to include "<title>Yale Center for British Art</title>"
      end
    end

    describe "#prepare_concat_field_with_trailing_period" do
      it "returns true" do
        v = [""]
        expect(helper.prepare_concat_field_with_trailing_period(v)).to be == ""
        v = ["a field"]
        expect(helper.prepare_concat_field_with_trailing_period(v)).to be == "a field."
        v = ["a field."]
        expect(helper.prepare_concat_field_with_trailing_period(v)).to be == "a field."
      end
    end

    describe "#prepare_concat_title_short" do
      it "returns true" do
        v = [""]
        expect(helper.prepare_concat_title_short(v)).to be == ""
        v = ["a field:"]
        expect(helper.prepare_concat_title_short(v)).to be == "a field."
        v = ["a field: "]
        expect(helper.prepare_concat_title_short(v)).to be == "a field."
        v = ["a field"]
        expect(helper.prepare_concat_title_short(v)).to be == "a field."
      end
    end

    describe "#concat_caption_marc" do
      it "returns true" do
        expect(helper.concat_caption_marc(document2)).to be == " Helmingham herbal and bestiary.  Helmingham, Suffolk, circa 1500. Yale Center for British Art, Paul Mellon Collection."
      end
    end

    describe "#concat_caption" do
      it "returns true" do
        expect(helper.concat_caption(document1)).to be == "Joseph Mallord William Turner, 1775–1851, British, Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed, 1818, Oil on canvas, Yale Center for British Art, Paul Mellon Collection, B1977.14.77"
      end
    end

    describe "#marc_field?" do
      it "returns true" do
        expect(helper.marc_field?(document2)).to be true
      end
    end

    describe "#copyrighted?" do
      it "returns true" do
        expect(helper.copyrighted?(document1)).to be false
        document = Hash.new
        document["rights_ss"] = ["under copyright"]
        expect(helper.copyrighted?(document)).to be true
      end
    end

    describe "#create_aeon_link_callnumber" do
      it "returns true" do
        document = document2
        callnumber = "Folio C 2014 4"
        mfhd_id = "9799201"
        expect(helper.create_aeon_link_callnumber(document,callnumber,mfhd_id)).to be == "<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=Folio C 2014 4&ItemTitle=Helmingham herbal and bestiary.&ItemAuthor=&ItemDate=1500&Format=1 v. ([20] leaves, with 1 blank leaf) : ill. ; 45 x 32 cm.&Location=bacrb&mfhdID=9799201&EADNumber=http://hdl.handle.net/10079/bibid/9452785' target='_blank'>Request</a>"
        document["collection_ss"] = ["Prints and Drawings"]
        document["format_ss"] = ["testformat"]
        #leave location_ss empty
        expect(helper.create_aeon_link_callnumber(document,callnumber,mfhd_id)).to be == "<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=Folio C 2014 4&ItemTitle=Helmingham herbal and bestiary.&ItemAuthor=&ItemDate=1500&Format=testformat&Location=&mfhdID=9799201&EADNumber=http://hdl.handle.net/10079/bibid/9452785' target='_blank'>Request</a>"
        document["collection_ss"] = ["Rare Books and Manuscripts"]
        expect(helper.create_aeon_link_callnumber(document,callnumber,mfhd_id)).to be == "<a href='https://aeon-test-mssa.library.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestMonograph&Site=YCBA&CallNumber=Folio C 2014 4&ItemTitle=Helmingham herbal and bestiary.&ItemAuthor=&ItemDate=1500&Format=1 v. ([20] leaves, with 1 blank leaf) : ill. ; 45 x 32 cm.&Location=bacrb&mfhdID=9799201&EADNumber=http://hdl.handle.net/10079/bibid/9452785' target='_blank'>Request</a>"
      end
    end

    describe "#get_bib_lookup" do
      it "returns true" do
        expect(helper.get_bib_lookup).to be == "https://libapp-test.library.yale.edu/VoySearch/GetBibItem?bibid="
      end
    end

    describe "#parse_mfhd" do
      it "returns true" do
        r = Hash.new
        allow(helper).to receive(:mfhd_path) do
          raise "boom"
        end
        expect(helper.parse_mfhd(r)).to be == ""
      end
    end

    describe "#get_frame_link_label" do
      it "returns true" do
        document = Hash.new
        document["collection_ss"] = ["Frames"]
        expect(helper.get_frame_link_label(document)).to be == "Link to Framed Image:"
        document["collection_ss"] = ["Paintings and Sculptures"]
        expect(helper.get_frame_link_label(document)).to be == "Link to Frame:"
      end
    end

    describe "#get_frame_link" do
      it "returns true" do
        stub_request(:post, "http://10.5.96.78:8983/solr/ycba_blacklight/select?fq=callnumber_ss:%22B1977.14.77FR%22&wt=json").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'Content-Length'=>'0',
                    'User-Agent'=>'Faraday v1.10.1'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_frame_BL.json')), headers: {})
        stub_request(:post, "http://10.5.96.78:8983/solr/ycba_blacklight/select?fq=callnumber_ss:%22B1977.14.77%22&wt=json").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'Content-Length'=>'0',
                    'User-Agent'=>'Faraday v1.10.1'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_BL.json')), headers: {})
        document = Hash.new
        document["callnumber_ss"] = ["B1977.14.77"]
        expect(helper.get_frame_link(document)).to be == "<a data-method=\"get\" href=\"http://test.host/catalog/tms:64431\">B1977.14.77FR</a>"
        document["callnumber_ss"] = ["B1977.14.77FR"]
        expect(helper.get_frame_link(document)).to be == "<a data-method=\"get\" href=\"http://test.host/catalog/tms:34\">B1977.14.77</a>"
      end
    end

    describe "#render_ycba_item_header" do
      it "returns true" do
        document = Hash.new
        #document["callnumber_ss"] = ["B1977.14.77"]
        document = document1
        expect(helper.render_ycba_item_header(document,:tag => :span, :fontsize => "20px")).to be == "<div style=\"text-align:center\" itemprop=\"name\" id=\"fullheader\"><span style=\"font-size: 20px\">Joseph Mallord William Turner, 1775–1851, British</span>, <span style=\"font-weight: bold; font-size: 20px\">Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed</span>, <span style=\"font-size: 20px\">1818</span></div>"
       end
    end

    describe "#get_download_array_from_manifest" do
      it "returns true" do
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/obj/34").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_iiif.json')), headers: {})
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/orb/9452785").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_iiif.json')), headers: {})
        @document = document1
        #puts helper.get_download_array_from_manifest
        downloads, restricted = helper.get_download_array_from_manifest
        expect(downloads.length).to be == 4
        expect(downloads[0]).to include "1"
        expect(downloads[0]).to include "recto, cropped to image"
        expect(downloads[0]).to include "https://images.collections.yale.edu/iiif/2/ycba:4f227f08-7842-46cc-b05a-e3c6a4614cc1/full/full/0/default.jpg"
        expect(downloads[0]).to include "https://media.collections.yale.edu/tiff/ycba/4f227f08-7842-46cc-b05a-e3c6a4614cc1.tif"
        @document = document2
        downloads, restricted = helper.get_download_array_from_manifest
        expect(downloads.length).to be == 26
        #puts helper.get_download_array_from_manifest
        expect(downloads[0]).to include "1"
        expect(downloads[0]).to include "folios 16v-17r"
        expect(downloads[0]).to include "https://images.collections.yale.edu/iiif/2/ycba:39b6a359-312c-4b71-84c1-349caaf3ff4b/full/full/0/default.jpg"
        allow(URI).to receive(:open) do
          raise "boom"
        end
        expect(helper.get_download_array_from_manifest[0].length).to be == 0
        #following 3 lines not needed to test
        #allow(JSON).to receive(:load) do
        #  JSON.generate({"items" => {}})
        #end
        #puts helper.get_download_array_from_manifest
        #expect(helper.get_download_array_from_manifest.length).to be == 0
      end
    end

    describe "#manifest_thumb?" do
      it "returns true" do
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/obj/34").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_iiif.json')), headers: {})
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/orb/9452785").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_iiif.json')), headers: {})
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/obj/1050").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','sickert_iiif.json')), headers: {})
        @document = document1
        expect(helper.manifest_thumb?).to be false
        @document = document2
        expect(helper.manifest_thumb?).to be false
        @document = document1
        @document['id'] = "tms:1050"
        expect(helper.manifest_thumb?).to be true
        allow(JSON).to receive(:load) do
          raise "boom"
        end
        expect(helper.manifest_thumb?).to be true
      end
    end

    describe "#manifest?" do
      it "returns true" do
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/obj/34").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','dort_iiif.json')), headers: {})
        stub_request(:get, "https://manifests.collections.yale.edu/ycba/orb/9452785").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'User-Agent'=>'Ruby'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','helmingham_iiif.json')), headers: {})
        @document = document1
        expect(helper.manifest?).to be true
        @document = document2
        expect(helper.manifest?).to be true
        allow(JSON).to receive(:parse) do
          raise "boom"
        end
        expect(helper.manifest?).to be false
      end
    end

    describe "#document_field_exists?" do
      it "returns true" do
        document = document1
        field = "title_ss"
        expect(helper.document_field_exists?(document,field)).to be true
      end
    end

    describe "#referenced_works?" do
      it "returns true" do
        stub_request(:post, "http://10.5.96.78:8983/solr/ycba_blacklight/select?fq=ilsnumber_ss:%22583000%22&rows=0&wt=json").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'Content-Length'=>'0',
                    'User-Agent'=>'Faraday v1.10.1'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','orbis_583000_numfound.json')), headers: {})

        document = Hash.new
        document["id"] = "orbis:583000"
        expect(helper.referenced_works?(document)).to be true
      end
    end

    describe "#link_to_referenced_ycba_objects" do
      it "returns true" do
        stub_request(:post, "http://10.5.96.78:8983/solr/ycba_blacklight/select?fq=ilsnumber_ss:%22583000%22&rows=0&wt=json").
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                    'Content-Length'=>'0',
                    'User-Agent'=>'Faraday v1.10.1'
                }).
            to_return(status: 200, body: File.new(Rails.root.join('spec','fixtures','orbis_583000_numfound.json')), headers: {})

        id = "orbis:583000"
        expect(helper.link_to_referenced_ycba_objects(id)).to be == "<a target=\"_blank\" rel=\"nofollow\" href=\"http://test.host/?utf8=✓&amp;search_field=Fielded&amp;q=ilsnumber_ss%3A583000\">View the 1223 Works referenced in this item</a>"
      end
    end

    describe "#handle_lido_collections" do
      it "returns true" do
        options = Hash.new
        options[:value] = ["Paintings and Sculpture"]
        options[:document] = {}
        options[:document][:callnumber_ss] = "B19701.1"
        expect(helper.handle_lido_collections(options)).to be == "Paintings and Sculpture"
        options[:document][:callnumber_ss] = "L1970.1"
        expect(helper.handle_lido_collections(options)).to be == "Paintings and Sculpture (Loan)"
      end
    end
  end
end
