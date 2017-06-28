require 'rails_helper'

RSpec.describe BookCoverController, type: :controller do

  describe "GET #show" do
    it "returns http success" do
      get :show, :params => { :isbn => '0521547903' }
      #get :show, isbn: '0521547903'
      expect(response).to have_http_status(:success)
    end
  end

end
