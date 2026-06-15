class PagesController < ApplicationController
  def bonjour
    @message = "Bienvenue dans l'app d'astreintes !"
    @heure   = Time.current.strftime("%H:%M")
  end
end