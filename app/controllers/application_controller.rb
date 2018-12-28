class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_fabrique
  def set_fabrique
    #set footer_bar variables
    @footer_bar_links = Array.new
    @footer_bar_links.push({:href=>"?", :title=>"Privacy & cookies"})
    @footer_bar_links.push({:href=>"?", :title=>"Terms of use"})
    @footer_bar_links.push({:href=>"?", :title=>"Colofon"})
  end
end
