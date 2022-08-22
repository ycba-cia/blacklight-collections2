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
      solrdoc = helper.get_solr_doc(@id1,"https://","collections-test.britishart.yale.edu")
      expect(solrdoc["callnumber_ss"][0]).to be == "B1977.14.77"
    end
  end

  describe "#print_fields" do
    it "gets tested" do
      @document = JSON.parse(File.read("spec/fixtures/dort.json"))
      printed_field1 = helper.print_fields("Title:","title_ss")
      expect(printed_field1).to be == "<dt style=\"overflow: hidden;\">Title:</dt><dd>Dort or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed</dd>"
      printed_field2 = helper.print_fields("Title:","empty_ss")
      expect(printed_field2).to be == ""
      printed_newline_field = helper.print_newline_fields("Creator:","author_ss")
      expect(printed_newline_field).to be == "<dt>Creator:</dt><dd><span>Joseph Mallord William Turner, 1775–1851, British</span></p></dd>"
      printed_default_empty1 = helper.print_fields_default_empty("Copyright Status:","ort_ss","Unknown")
      expect(printed_default_empty1).to be == "<dt>Copyright Status:</dt><dd>Public Domain</dd>"
      printed_default_empty2 = helper.print_fields_default_empty("Copyright Status:","empty_ss","Unknown")
      expect(printed_default_empty2).to be == "<dt>Copyright Status:</dt><dd>Unknown</dd>"
      printed_sep_fields1 = helper.print_sep_fields("Subject Terms:","topic_ss")
      expect(printed_sep_fields1).to be == "<dt>Subject Terms:</dt><dd>marine art | crowd | sea | church | costume | jars | ship | ships | market (event) | women | sunlight | men | cityscape | flags | seascape | rowboats | fruit | rubbish | reflection | chromaticity | river | city | flotsam | vegetables</dd>"
      printed_sep_fields2 = helper.print_sep_fields("Subject Terms:","empty_ss")
      expect(printed_sep_fields2).to be == ""

      @document = JSON.parse(File.read("spec/fixtures/helmingham.json"))
      printed_field = helper.print_fields("Title:","title_ss")
      expect(printed_field).to be == "<dt style=\"overflow: hidden;\">Title:</dt><dd>Helmingham herbal and bestiary.</dd>"
      printed_newline_field = helper.print_newline_fields("Creator:","author_ss")
      expect(printed_newline_field).to be == ""
      printed_default_empty1 = helper.print_fields_default_empty("Copyright Status:","ort_ss","Unknown")
      expect(printed_default_empty1).to be == "<dt>Copyright Status:</dt><dd>Copyright Information</dd>"
      printed_default_empty2 = helper.print_fields_default_empty("Copyright Status:","empty_ss","Unknown")
      expect(printed_default_empty2).to be == "<dt>Copyright Status:</dt><dd>Unknown</dd>"
      printed_sep_fields = helper.print_sep_fields("Subject Terms:","topic_ss")
      expect(printed_sep_fields).to be == "<dt>Subject Terms:</dt><dd>Tollemache family. | Bodleian Library. Manuscript. Ashmole 1504. | Helmingham Hall. | Agnus castus (Middle English herbal) | Hortus sanitatis. | Animals, Mythical, in art. | Animals in art. | Animals -- Folklore. | Plants in art. | Decoration and ornament -- England. | Interior decoration -- England.</dd>"
    end
  end

end