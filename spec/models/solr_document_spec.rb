require "rails_helper"
require "citations"
RSpec.describe SolrDocument do
  describe "access methods" do
    let(:solrdoc) do
      SolrDocument.new(JSON.parse(File.open("spec/fixtures/prue.json","rb").read))
    end

    describe "#[]" do
      subject { solrdoc[field] }

      context "with format" do
        let(:field) { :access_facet }
        it { is_expected.to eq ['Open access'] }
      end

    end

    describe "#" do
      subject { solrdoc.author }
      context "with author" do
        #NOTE: added fake author_additional_ss to prue.json
        it { is_expected.to eq ["Sir Joshua Reynolds RA, 1723–1792, British","Sir Fake Author 1","Sir Fake Author 2"] }
      end
    end

    it "can retrieve a short title" do
      expect(solrdoc.title).to eq ["Mrs. Abington as Miss Prue in \"Love for Love\" by William Congreve"]
    end

    describe "#id" do
      subject { solrdoc.id }
      it { is_expected.to eq '1669236' }
    end
  end
end