class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_fabrique

  skip_after_action :discard_flash_if_xhr

  def set_fabrique
    #question how to manage changes here when deployed to heroku?
    #set footer_bar variables
    @footer_bar_links = Array.new
    @footer_bar_links.push({:href=>"?", :title=>"Privacy & cookies"})
    @footer_bar_links.push({:href=>"?", :title=>"Terms of use"})
    @footer_bar_links.push({:href=>"?", :title=>"Colofon"})

=begin
    @footeritems = Array.new
    item1 = {:href=>"?", :title=>"Privacy & cookies"}
    items = [item1]
    @footeritems.push({:title=>"", :text=>"1080 Chapel Street,<br/>New Haven, Connecticut",:linked_list =>items})
    item1 = {:property=>"Tue &mdash; Sat", :value=>"10am &mdash; 5pm"}
    item2 = {:property=>"Sunday", :value=>"12am &mdash; 5pm"}
    item3 = {:property=>"Monday", :value=>"Closed"}
    items = [item1,item2,item3]
    @footeritems.push(:title=>"", :text=>"Admission is free",:definition_list=>items})
    item1 = {:href=>"?",:title=>"What to expect"}
    item2 = {:href=>"?",:title=>"Tours & guides"}
    item3 = {:href=>"?",:title=>"City & the region"}
    item4 = {:href=>"?",:title=>"Accessibility"}
    items = [item1,item2,item3,item4]
    @footeritems.push(:title=>"",:linked_list=>items})
    item1 = {:title=>}
=end

    @footeritems = [{text:"1080 Chapel Street<br/>New Haven, Connecticut",
                     link_list:[["Plan your visit","?"]]},
                    {text:"Admission is free",
                     definition_list:[["Tue &mdash; Sat","10am &mdash; 5pm"],
                                ["Sunday","12am &mdash; 5pm"],
                                ["Monday","Closed"]]},
                    {link_list:[["Tours","?"],
                                ["City & region","?"],
                                ["Directions & parking","?"],
                                ["Accessibility","?"]]},
                    {follow_buttons:"true"},
                    {title:"What's on",
                     link_list:[["Now & upcoming","?"],
                                ["Past","?"]]},
                    {title:"Collections",
                     link_list:[["Search the collections","?"],
                                ["Highlights","?"],
                                ["How to use the collection","?"]]},
                    {title:"Research & Learning",
                     link_list:[["Yale Students","?"],
                                ["Scholars","?"],
                                ["K-12 Teachers","?"],
                                ["Community","?"],
                                ["Colleges & Universities","?"],
                                ["Publications & recordings","?"],
                                ["Library & study room","?"]]},
                    {title:"About us",
                     link_list:[["Our story","?"],
                                ["Paul Mellon Centre","?"],
                                ["Architecture","?"],
                                ["Staff & departments","?"],
                                ["News & press","?"],
                                ["Get involved","?"],
                                ["Contact","?"]]}]
  end
end
