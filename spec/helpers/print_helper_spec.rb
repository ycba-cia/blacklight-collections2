require 'spec_helper'

describe PrintHelper do

  before(:all) do
    #@id
    @size = 1
    @index = 0

    @manifest = "https://manifests.collections.yale.edu/ycba/obj/34"
    @id1 = "tms:34"
    @image1 = "https://images.collections.yale.edu/iiif/2/ycba:4f227f08-7842-46cc-b05a-e3c6a4614cc1/full/full/0/default.jpg"
    @markup = "<div style=\"page-break-after: always\"><img class=\"contain\" src=\"https://images.collections.yale.edu/iiif/2/ycba:4f227f08-7842-46cc-b05a-e3c6a4614cc1/full/full/0/default.jpg\" width=\"700\" height=\"800\" style=\"object-fit: contain;\"></div>"

    @id2 = "orbis:9452785"
    @image2 = "https://images.collections.yale.edu/iiif/2/ycba:39b6a359-312c-4b71-84c1-349caaf3ff4b/full/full/0/default.jpg"

    @pixels = ["700","800"]
    @index = 0

  end

  describe "#get_images_from_iiifv3" do
    it "gets tested" do
      images, pixels = helper.get_images_from_iiifv3(@manifest,@index)
      expect(images[0]).to be == @image1
      expect(pixels[0]).to be == @pixels
    end
  end
  describe "#get_images_from_cds2" do
    it "gets tested" do
      images1, pixels1 = helper.get_images_from_cds2(@id1,@index)
      images2, pixels2 = helper.get_images_from_cds2(@id2,@index)
      expect(images1[0]).to be == @image1
      expect(pixels1[0]).to be == @pixels
      expect(images2[0]).to be == @image2
      expect(pixels2[0]).to be == @pixels
    end
  end
  describe "#print_images" do
    it "gets tested" do
      markup = helper.print_images(@id1,@index)
      expect(markup).to be == @markup
    end
  end
  describe "#get_solr_doc" do
    it "gets tested" do
      mock = double("request")
      solrdoc = helper.get_solr_doc(@id1,"https://","collections-test.britishart.yale.edu")
      expect(solrdoc["callnumber_ss"][0]).to be == "B1977.14.77"
    end
  end

end