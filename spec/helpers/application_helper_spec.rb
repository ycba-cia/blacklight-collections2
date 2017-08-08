require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
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
end
