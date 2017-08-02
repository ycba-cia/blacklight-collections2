require "rails_helper"
require "citations"
RSpec.describe SolrDocument do
  describe "access methods" do
    let(:solrdoc) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/prue.json","rb").read))
    end

    let(:solrdoc2) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/leighton.json","rb").read))
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

    describe "#id" do
      subject { solrdoc.id }
      it { is_expected.to eq '1669236' }
    end

    it "can strip punctuation" do
      s = "This., -/ is #! an $ % ^ & * example ;: {} of a = -_ string with `~)() punctuation. "
      ss = "This - is #! an $ % ^ & * example  {} of a = -_ string with `~)() punctuation"
      expect(solrdoc.stripPunctuation(s)).to eq ss
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

  end
end