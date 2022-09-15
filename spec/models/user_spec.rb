require "rails_helper"
RSpec.describe SolrDocument do
  describe "access methods" do
    it "tests needs_attr_accessible?" do
      allow(Blacklight::Utils).to receive(:needs_attr_accessible?).and_return(true)
      #Blacklight::Utils.stub(:needs_attr_accessible?).and_return(true)
      user = User.new
      user.email = "user@yale.edu"
      user.password = "password123"
      expect(user).to be_valid
      expect(user.to_s).to be == "user@yale.edu"
    end

  end
end
