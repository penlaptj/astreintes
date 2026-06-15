Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root → login. Redirige vers /register_admin si aucun admin n'existe.
  root to: "sessions#login"

  #------Auth---------#
  get    "/login",            to: "sessions#login"
  post   "/login",            to: "sessions#create"
  get    "/register",         to: "sessions#register"
  post   "/register",         to: "sessions#new"
  get    "/register_admin",   to: "sessions#register_admin"
  post   "/register_admin",   to: "sessions#bootstrap_admin"
  delete "/logout",           to: "sessions#destroy"

  #------Slots CRUD---------#
  get    "/slots",          to: "slots#slots"
  get    "/slots/new",      to: "slots#new"
  post   "/slots/create",   to: "slots#create"
  get    "/slots/:id/edit", to: "slots#edit"
  patch  "/slots/:id",      to: "slots#update"
  delete "/slots/:id",      to: "slots#destroy"

  #------Slots Actions métier---------#
  get  "/slots/validation",        to: "slots#validation"
  post "/slots/:id/assign",        to: "slots#assign"
  post "/slots/:id/take/:id_user", to: "slots#take"
  post "/slots/:id/release",       to: "slots#release"
  post "/slots/:id/unassign",      to: "slots#release"
  post "/slots/:id/validate",      to: "slots#validate_request"
  post "/slots/:id/reject",        to: "slots#reject_request"
  post "/slots/:id/swap",          to: "slots#swap"

  #------Vues utilisateur---------#
  get "/mes_astreintes",              to: "slots#mes_astreintes"
  get "/users/:user_id/slots",        to: "slots#index"
  get "/users/:user_id/slots/export", to: "slots#export_user", as: :export_user_slots, defaults: { format: :xlsx }
  get "/calendar",                    to: "slots#calendar"
  get "/profile",                     to: "users#profile"
  get    "/preferences",                  to: "users#preferences"
  patch  "/preferences",                  to: "users#update_preferences"
  post   "/preferences/test_notification", to: "users#test_notification"
  delete "/preferences/telegram_link",    to: "users#unlink_telegram"
  get "/security",                    to: "users#security"

  #------Gestion utilisateurs (admin)---------#
  get    "/users/new",                to: "users#new"
  post   "/users",                    to: "users#create"
  post   "/users/:id/change_role",    to: "users#change_role"
  post   "/users/:id/change_service", to: "users#change_service"
  post   "/users/:id/disable",        to: "users#disable"
  post   "/users/:id/enable",         to: "users#enable"
  delete "/users/:id",                to: "users#destroy"
  patch  "/users/update_password",    to: "users#update_password"
  

  #------Invitations (définition du mot de passe)---------#
  get   "/invitations/:token", to: "invitations#edit",   as: :accept_invitation
  patch "/invitations/:token", to: "invitations#update"

  #------Dashboard---------#
  get "/dashboard",                to: "dashboards#dashboard_users"
  get "/dashboard/users",          to: "dashboards#dashboard_users"
  get "/dashboard/astreintes",     to: "dashboards#dashboard_astreintes"
  get "/dashboard/recaps",         to: "dashboards#dashboard_recaps"
  get "/dashboard/history",        to: "dashboards#dashboard_history"
  get "/dashboard/recaps/export",  to: "dashboards#export", as: :export_recaps, defaults: { format: :xlsx }

  #------Notifications---------#
  get  "/notifications",                              to: "notifications#index"
  get  "/notifications/system",                       to: "notifications#system"
  get  "/notifications/sender/:sender_id",            to: "notifications#show_by_sender"
  get  "/notifications/sidebar",                      to: "notifications#sidebar"
  post "/notification/create",                        to: "notifications#create"
  post "/notification/:notification_id/mark_as_read", to: "notifications#markAsRead"
  

  #------Divers---------#
  get  "/bonjour",          to: "pages#bonjour"
  get  "/recap",            to: "slots#recap"
  post "/slots/:id/notify", to: "slots#notify"

  post "/webhooks/grafana",  to: "webhooks#grafana"
  post "/webhooks/uptime",   to: "webhooks#uptime"
  post "/webhooks/telegram", to: "webhooks#telegram"

  #------Services (gestion admin)---------#
  resources :services, except: [:show]

  #-----SSO-----#
  match "/auth/saml/callback", to: "sessions#saml_callback", via: [:get, :post]
  get   "/auth/failure",       to: "sessions#saml_failure"

end
