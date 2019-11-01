class PrintController < ApplicationController
  include PrintHelper

  def show
    @id = params[:id]
    @size = params[:size]
    @images = print_images(@id)
    render layout: false
  end
end