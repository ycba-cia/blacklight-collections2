require "rails_helper"
require "citations"
#http://collections.britishart.yale.edu/vufind/Record/2038711/Cite
#http://collections.britishart.yale.edu/vufind/Record/1669236/Cite
RSpec.describe SolrDocument do
  describe "access methods" do
    let(:solrdoc) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/dort.json","rb").read))
    end

    let(:solrdoc2) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/helmingham.json","rb").read))
    end

    let(:solrdoc3) do
      SolrDocument.new(id: "01234567", edition_ss: ["1st ed."], author_ss: ["Leighton, Clare, 1898-1989.","name2","me","you","him"],
                       publisher_ss: ["New Haven : YCBA Madeup Press"], title_ss: ["a title"], publishDate_ss: ["1975"],
                       title_short_ss: ["a short title"])
    end

    let(:solrdoc4) do
      SolrDocument.new(id: "1234568", edition_ss: ["2nd ed."],author_ss: ["Apple","Bear"])
    end

    let(:solrdoc5) do
      SolrDocument.new(id: "1234568", edition_ss: ["2nd ed"],author_ss: ["Apple","Bear","Cat"])
    end

    describe "#[]" do
      subject { solrdoc[field] }

      context "with format" do
        let(:field) { :access_ss }
        it { is_expected.to eq ['Open access'] }
      end

    end

    describe "#" do
      subject { solrdoc.authors }
      context "with author" do
        #NOTE: added fake author_additional_ss to prue.json
        it { is_expected.to eq ["Joseph Mallord William Turner, 1775–1851, British"] }
      end
    end

    describe "#" do
      subject { solrdoc2.authors }
      context "with author" do
        #NOTE: added fake author_additional_ss to prue.json
        it { is_expected.to eq ["Sangorski & Sutcliffe, binder."] }
      end
    end

    describe "#" do
      subject { solrdoc3.authors }
      context "with author" do
        #NOTE: added fake author_additional_ss to prue.json
        it { is_expected.to eq ["Leighton, Clare, 1898-1989.", "name2", "me", "you", "him"] }
      end
    end

    it "can retrieve a short title" do
      expect(solrdoc.title).to eq ["Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed"]
      expect(solrdoc2.title).to eq ["Helmingham herbal and bestiary."]
    end

    it "can retrieve a publisher" do
      expect(solrdoc2.publisher_cit).to eq ["Helmingham, Suffolk, circa 1500."]
    end

    it "can retrieve a publishDate" do
      expect(solrdoc.publishDate).to eq ["1818"]
      expect(solrdoc2.publishDate).to eq ["circa 1500"]
    end

    it "can retrieve an edition" do
      expect(solrdoc3.edition).to eq ["1st ed."]
    end

    it "can't retrieve a pub place" do
      expect(solrdoc.pubPlace).to eq [""]
    end

    describe "#id" do
      subject { solrdoc.id }
      it { is_expected.to eq "tms:34" }
    end

    it "can strip punctuation" do
      s = "This., -/ is #! an $ % ^ & * example ;: {} of a = -_ string with `~)() punctuation. "
      ss = "This - is #! an $ % ^ & * example  {} of a = -_ string with `~)() punctuation"
      sss = ""
      expect(solrdoc.stripPunctuation(s)).to eq ss
      expect(solrdoc.stripPunctuation(sss)).to eq ""
      expect(solrdoc.stripPunctuation(nil)).to eq ""
    end

    it "is punctuated" do
      s = "asdf"
      s2 = "asdf."
      expect(solrdoc.isPunctuated(s)).to eq false
      expect(solrdoc.isPunctuated(s2)).to eq true
    end

    it "can validate a date range" do
      s1 = "1900"
      s2 = "1900-"
      s3 = "1900-2000"
      expect(solrdoc.isDateRange?(s1)).to be false
      expect(solrdoc.isDateRange?(s2)).to be true
      expect(solrdoc.isDateRange?(s3)).to be true
    end

    it "can abbreviate a name" do
      s1 = "Bush, George Herbert Walker, 1920-"
      s2 = "Leighton, Clare, 1898-1989."
      s3 = "Sir Joshua Reynolds RA, 1723–1792, British"
      s4 = "Sir Fake Author 1"
      expect(solrdoc.abbreviateName(s1)).to eq "Bush, G. H. W."
      expect(solrdoc.abbreviateName(s2)).to eq "Leighton, C."
      expect(solrdoc.abbreviateName(s3)).to eq "Sir Joshua Reynolds RA"
      expect(solrdoc.abbreviateName(s4)).to eq "Sir Fake Author 1"
    end

    it "can MLA capitalize a title" do
      t1 = "Mrs. Abington as Miss Prue in \"Love for Love\" by William Congreve"
      t2 = "Clare Leighton collection"
      t3 = ""
      t4 = "Note: try capitalize after a colon"
      expect(solrdoc.capitalizeTitle(t1)).to eq "Mrs. Abington As Miss Prue in \"love for Love\" By William Congreve"
      expect(solrdoc.capitalizeTitle(t2)).to eq "Clare Leighton Collection"
      expect(solrdoc.capitalizeTitle(t3)).to eq ""
      expect(solrdoc.capitalizeTitle(t4)).to eq "Note: Try Capitalize After a Colon"
    end

    it "distinguishes a suffix" do
      s1 = nil
      s2 = ""
      s3 = "Jr"
      s4 = "XCLVII"
      s5 ="random"
      expect(solrdoc.isNameSuffix?(s1)).to eq false
      expect(solrdoc.isNameSuffix?(s2)).to eq false
      expect(solrdoc.isNameSuffix?(s3)).to eq true
      expect(solrdoc.isNameSuffix?(s4)).to eq true
      expect(solrdoc.isNameSuffix?(s5)).to eq false
    end

    it "cleans MLA nameDates" do
      s1 = "Leighton, Clare, 1898-1989."
      s2 = "Josiah Wedgwood & Sons."
      s3 = "Sir Joshua Reynolds RA, 1723–1792"
      s4 = "Jones Jr, Indiana, 1910-2000"
      s5 = ""
      s6 = "Jones, Indiana, Jr"
      expect(solrdoc.cleanNameDates(s1)).to eq "Leighton, Clare"
      expect(solrdoc.cleanNameDates(s2)).to eq "Josiah Wedgwood & Sons."
      expect(solrdoc.cleanNameDates(s3)).to eq "Sir Joshua Reynolds RA"
      expect(solrdoc.cleanNameDates(s4)).to eq "Jones Jr, Indiana"
      expect(solrdoc.cleanNameDates(s5)).to eq ""
      expect(solrdoc.cleanNameDates(s6)).to eq "Jones, Indiana, Jr"
    end

    it "reverses names for MLA" do
      s1 = "Leighton, Clare, 1898-1989."
      s2 = "Josiah Wedgwood & Sons."
      s3 = "Sir Joshua Reynolds RA, 1723–1792"
      s4 = "Jones Jr, Indiana, 1910-2000"
      s5 = ""
      s6 = "Jones, Indiana, Jr"
      expect(solrdoc.reverseName(s1)).to eq "Clare Leighton"
      expect(solrdoc.reverseName(s2)).to eq "Josiah Wedgwood & Sons."
      expect(solrdoc.reverseName(s3)).to eq "Sir Joshua Reynolds RA"
      expect(solrdoc.reverseName(s4)).to eq "Indiana Jones Jr"
      expect(solrdoc.reverseName(s5)).to eq ""
      expect(solrdoc.reverseName(s6)).to eq "Indiana Jones, Jr"
    end

    it "render an MLA title" do
      expect(solrdoc.getMLATitle).to eq "Dort or Dordrecht: The Dort Packet-boat From Rotterdam Becalmed"
      expect(solrdoc2.getMLATitle).to eq "Helmingham Herbal and Bestiary."
    end

    it "renders an APA title" do
      expect(solrdoc.getAPATitle).to eq "Dort or Dordrecht The Dort Packet-Boat from Rotterdam Becalmed"
      expect(solrdoc2.getAPATitle).to eq "Helmingham herbal and bestiary"
    end

    it "renders an MLA author" do
      expect(solrdoc.getMLAAuthors).to eq "Joseph Mallord William Turner."
      expect(solrdoc2.getMLAAuthors).to eq "Sangorski & Sutcliffe, binder.."
      expect(solrdoc3.getMLAAuthors).to eq "Leighton, Clare, et al"
      expect(solrdoc4.getMLAAuthors).to eq "Apple, and Bear."
      expect(solrdoc5.getMLAAuthors).to eq "Apple, Bear, and Cat."
    end

    it "renders an APA author" do
      expect(solrdoc.getAPAAuthors).to eq "Joseph Mallord William Turner."
      expect(solrdoc2.getAPAAuthors).to eq "Sangorski & Sutcliffe b."
      expect(solrdoc3.getAPAAuthors).to eq "Leighton C, name2, me, you, & him."
    end

    it "renders a publisher" do
      expect(solrdoc2.getPublisher).to eq "Helmingham, Suffolk, circa 1500."
    end

    it "renders a year" do
      expect(solrdoc.getYear).to eq "1818"
      expect(solrdoc2.getYear).to eq "circa 1500"
    end

    it "renders an edition" do
      expect(solrdoc3.getEdition).to eq ""
      expect(solrdoc4.getEdition).to eq "2nd ed."
      expect(solrdoc5.getEdition).to eq "2nd ed."
    end

    it "renders full APA" do
      apaHash = Hash.new
      apaHash["authors"] = "Leighton C, name2, me, you, & him."
      apaHash["edition"] = ""
      apaHash["publisher"] = "New Haven : YCBA Madeup Press"
      apaHash["title"] = "a short title."
      apaHash["year"] = "(1975)."
      expect(solrdoc3.getAPA).to eq apaHash
    end

    it "renders full MLA" do
      mlaHash = Hash.new
      mlaHash["authors"] = "Leighton, Clare, et al"
      mlaHash["edition"] = ""
      mlaHash["publisher"] = "New Haven : YCBA Madeup Press"
      mlaHash["title"] = "a Short Title."
      mlaHash["year"] = "1975."
      expect(solrdoc3.getMLA).to eq mlaHash
    end

    it "tests physical_description" do
      expect(solrdoc.physical_description).to eq ["Support (PTG): 62 × 92 inches (157.5 × 233.7 cm)",
                                                  "Frame: 73 × 102 × 5 inches (185.4 × 259.1 × 12.7 cm)"]
    end

    it "tests publisher" do
      expect(solrdoc2.publisher).to eq "Helmingham, Suffolk, circa 1500."
    end

    it "tests all _acc" do
      expect(solrdoc2.orbis_link_acc[0]).to eq "http://hdl.handle.net/10079/bibid/9452785"
      expect(solrdoc2.callnumber_acc).to eq nil
      expect(solrdoc2.note_acc[0]).to eq "Barker, Nicholas, ed. Two East Anglian picture books : a facsimile of the Helmingham herbal and bestiary and Bodleian ms. Ashmole 1504. (London: Roxburghe Club, 1988)."
      expect(solrdoc2.title_acc[0]).to eq "Helmingham herbal and bestiary."
      expect(solrdoc2.author_acc).to eq nil
      expect(solrdoc2.physical_acc[0]).to eq "1 v. ([20] leaves, with 1 blank leaf) : ill. ; 45 x 32 cm."
      expect(solrdoc2.collection_acc[0]).to eq "Rare Books and Manuscripts"
      expect(solrdoc2.credit_line_acc[0]).to eq "Yale Center for British Art, Paul Mellon Collection"
      expect(solrdoc2.type_acc[0]).to eq "Archives & Manuscripts"
      expect(solrdoc2.topic_acc[0]).to eq "Tollemache family."
      expect(solrdoc2.exhibition_history_acc[0]).to eq "\" Of Green Leaf, Bird, and Flower \" : Artists' Books and the Natural World (Yale Center for British Art, 2014-05-15 - 2014-08-10)"
      expect(solrdoc2.dummy_ort_marc_acc).to eq "orbis:9452785"
      expect(solrdoc.dummy_ort_lido_acc).to eq "tms:34"
      expect(solrdoc2.detailed_onview_acc[0]).to eq "View by request in the Study Room"
      expect(solrdoc2.titles_primary_acc[0]).to eq "Helmingham herbal and bestiary."
      expect(solrdoc2.titles_former_acc).to eq nil
      expect(solrdoc2.titles_additional_acc[0]).to eq "Helmingham bestiary"
    end

    it "tests cds_url" do
      expect(solrdoc2.cds_url).to eq "9452785"
    end

    it "test cite_as" do
      expect(solrdoc2.cite_as).to eq "Yale Center for British Art"
    end

  end
end