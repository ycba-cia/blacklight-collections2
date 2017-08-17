require "rails_helper"
require "citations"
#http://collections.britishart.yale.edu/vufind/Record/2038711/Cite
#http://collections.britishart.yale.edu/vufind/Record/1669236/Cite
RSpec.describe SolrDocument do
  describe "access methods" do
    let(:solrdoc) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/prue.json","rb").read))
    end

    let(:solrdoc2) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/leighton.json","rb").read))
    end

    let(:solrdoc3) do
      SolrDocument.new(id: '01234567', edition_ss: ['1st ed.'],author_ss: ["Leighton, Clare, 1898-1989.","name2","me","you","him"])
    end

    describe "#[]" do
      subject { solrdoc[field] }

      context "with format" do
        let(:field) { :access_facet }
        it { is_expected.to eq ['Open access'] }
      end

    end

    describe "#" do
      subject { solrdoc.authors }
      context "with author" do
        #NOTE: added fake author_additional_ss to prue.json
        it { is_expected.to eq ["Sir Joshua Reynolds RA, 1723–1792, British","Sir Fake Author 1","Sir Fake Author 2"] }
      end
    end

    describe "#" do
      subject { solrdoc2.authors }
      context "with author" do
        #NOTE: added fake author_additional_ss to prue.json
        it { is_expected.to eq ["Leighton, Clare, 1898-1989.","Josiah Wedgwood & Sons."] }
      end
    end

    it "can retrieve a short title" do
      expect(solrdoc.title).to eq ["Mrs. Abington as Miss Prue in \"Love for Love\" by William Congreve"]
      expect(solrdoc2.title).to eq ["Clare Leighton collection,"]
    end

    it "can retrieve a publisher" do
      #NOTE: added fake publisher_ss to prue.json, leighton.json
      expect(solrdoc.publisher_cit).to eq ["New Haven : YCBA Madeup Press"]
      expect(solrdoc2.publisher_cit).to eq ["Hamden : YUL Madeup Press"]
    end

    it "can retrieve a publishDate" do
      expect(solrdoc.publishDate).to eq ["1771"]
      #NOTE: added fake publishDate_ss to leighton.json
      expect(solrdoc2.publishDate).to eq ["2075"]
    end

    it "can retrieve an edition" do
      #NOTE:added fake edition to prue.json, leighton.json
      expect(solrdoc.edition).to eq ["99th ed."]
      expect(solrdoc2.edition).to eq ["101th ed."]
    end

    it "can't retrieve a pub place" do
      expect(solrdoc.pubPlace).to eq [""]
    end

    describe "#id" do
      subject { solrdoc.id }
      it { is_expected.to eq '1669236' }
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
      expect(solrdoc.cleanNameDates(s1)).to eq "Leighton, Clare"
      expect(solrdoc.cleanNameDates(s2)).to eq "Josiah Wedgwood & Sons."
      expect(solrdoc.cleanNameDates(s3)).to eq "Sir Joshua Reynolds RA"
      expect(solrdoc.cleanNameDates(s4)).to eq "Jones Jr, Indiana"
      expect(solrdoc.cleanNameDates(s5)).to eq ""
    end

    it "reverses names for MLA" do
      s1 = "Leighton, Clare, 1898-1989."
      s2 = "Josiah Wedgwood & Sons."
      s3 = "Sir Joshua Reynolds RA, 1723–1792"
      s4 = "Jones Jr, Indiana, 1910-2000"
      s5 = ""
      expect(solrdoc.reverseName(s1)).to eq "Clare Leighton"
      expect(solrdoc.reverseName(s2)).to eq "Josiah Wedgwood & Sons."
      expect(solrdoc.reverseName(s3)).to eq "Sir Joshua Reynolds RA"
      expect(solrdoc.reverseName(s4)).to eq "Indiana Jones Jr"
      expect(solrdoc.reverseName(s5)).to eq ""
    end

    it "render an MLA title" do
      expect(solrdoc.getMLATitle).to eq "Mrs. Abington As Miss Prue in \"love for Love\" By William Congreve"
      expect(solrdoc2.getMLATitle).to eq "Clare Leighton Collection,"
    end

    it "renders an APA title" do
      expect(solrdoc.getAPATitle).to eq "Mrs Abington as Miss Prue in \"Love for Love\" by William Congreve"
      expect(solrdoc2.getAPATitle).to eq "Clare Leighton collection"
    end

    it "renders an MLA author" do
      expect(solrdoc.getMLAAuthors).to eq "Sir Joshua Reynolds RA 1723–1792 British, Sir Fake Author 1, and Sir Fake Author 2."
      expect(solrdoc2.getMLAAuthors).to eq "Leighton, Clare, and Josiah Wedgwood & Sons"
      expect(solrdoc3.getMLAAuthors).to eq "Leighton, Clare, et al"
    end

    it "renders an APA author" do
      expect(solrdoc.getAPAAuthors).to eq "Sir Joshua Reynolds RA, Sir Fake Author 1, & Sir Fake Author 2."
      expect(solrdoc2.getAPAAuthors).to eq "Leighton C, & Josiah Wedgwood & Sons."
    end

    it "renders a publisher" do
      expect(solrdoc.getPublisher).to eq "New Haven : YCBA Madeup Press"
      expect(solrdoc2.getPublisher).to eq "Hamden : YUL Madeup Press"
    end

    it "renders a year" do
      expect(solrdoc.getYear).to eq "1771"
      expect(solrdoc2.getYear).to eq "2075"
    end

    it "renders an edition" do
      #NOTE:added fake edition to prue.json, leighton.json
      expect(solrdoc.getEdition).to eq "99th ed."
      expect(solrdoc2.getEdition).to eq "101th ed."
      expect(solrdoc3.getEdition).to eq ""
    end

  end
end