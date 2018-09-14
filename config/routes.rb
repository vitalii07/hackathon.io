require 'resque/server'
HackIO::Application.routes.draw do
  # Health Check
  match 'status' => "status#show"

  ActiveAdmin.routes(self)
  devise_for :admin_users, ActiveAdmin::Devise.config
  constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.kind_of?(AdminUser) }
  constraints constraint do
    mount Resque::Server.new, :at => "/resque"
    match "docs" => "docs#index"
  end

  # Static Routes
  match "/home"                    => "home#index"                  , as: :home
  match "/features"                => 'site#features'               , as: :features
  match "/team"                    => 'site#team'                   , as: :team
  match "/about"                   => 'site#about'                  , as: :about
  match "/terms"                   => 'site#terms'                  , as: :terms
  match "/privacy"                 => 'site#privacy'                , as: :privacy
  match "/dmca"                    => 'site#dmca'                   , as: :dmca
  match "/sitemap"                 => 'site#sitemap'                , as: :sitemap

  match '/login(/:purpose)'        => 'user_sessions#new'           , as: :login
  match '/logout'                  => 'user_sessions#destroy'       , as: :logout
  match '/support'                 => "users/settings#support"      , as: :support

  match '/join'                    => 'users#join'                  , as: :join
  match '/join/register'           => 'users#new'                   , as: :register
  match '/finish_signup'           => 'user_sessions#finish_signup' , as: :finish_signup
  match '/auth/:provider/callback' => "Users::Accounts#callback"
  match '/i/:code'                 => "invitations#accept"          , as: :accept_invite
  match '/message_router/receive'  => "message_router#receive"
  match '/network'                 => "users#network"               , as: :network

  (match "/play"                    => "home#play"                  , as: :plays ) if Rails.env.development?

  #match '/users/:id/more'          => 'users#more'

  #match '/users/:user_id/emails/:confirmation_code/validate' => "Users::Emails#validate", as: :validate_email
  FlowController.flows.each do |flow|
    flow = "#{flow}_flow"
    match "#{flow}/(*action)", :controller => flow, :as => flow
  end

  resources :contest_subscribers, only: [:create]

  resources :user_sessions,   only: [:new, :create]
  resources :forgot_password, only: [:new, :create] do
    collection do
      get :change_password
      put :update_password
    end
  end

  resources :users do
    collection do
      get :network
    end

    member do
      get :more
      post "like"
      delete "like", action: :unlike
    end

    scope :module => "users" do
      resource :settings
      resources :emails do
        collection do
          get :validate
        end
        member do
          get :verify
          get :make_default
        end
      end

      resource :profile do
        collection do
          get :remove_picture
          get :skip
        end
      end
      resources :platforms
      resources :events,   :only => [ :index ]
      resources :projects, :only => [ :index ]
    end

    resources :accounts
    resources :user_projects
    resources :confirmations
    collection do
      get :register_email
    end
  end

  scope :module => "events" do
    resources :events do
      member do
        post :publish
        get :chats
        get :tweets
        post :receive
        get :live
      end

      resources :emails

      resources :users, :path => 'people' do
        collection do
          get :join
          get :leave
          get :edit_multiple
          put :update_multiple
        end
        member do
          get :make_admin
          get :remove_admin
          get :make_judge
          get :remove_judge
        end
      end

      resources :prizes do
        collection do
          get :edit_multiple
          put :update_multiple
          get :sort_order
        end
      end

      resources :schedules do
        collection do
          get :edit_multiple
          put :update_multiple
        end
      end

      resources :sponsors do
        collection do
          get :org_new
          post :org_create
          get :edit_multiple
        end
      end

      resources :projects do
        collection do
          get :select
          get :submit
          get :presenting
        end
      end

      resources :submissions do
        member do
          get :judge_project
        end
        collection do
          get :judge
          get :results
          get :edit_multiple
        end
      end
      resources :activities
      resource  :description
      resource  :wiki
      resource  :rules
      resources :votes
      resource  :submissions_bulk,
                :only       => :create,
                :controller => :submission_bulk_updates

      resources :judging_criteria
      resources :photos, only: [:index]

      member do
        get 'judge'
        get 'import'
        put 'eb_admin', action: 'eb_admin_update'
        post 'eb_import_attendees'
        get 'eb_claim'
        get 'eb_process_claim'
      end
    end
  end

  resources :organizations do
    resources :memberships, :controller => "organization_memberships"
  end

  resources :projects do
    post "like", on: :member
    delete "like", on: :member, action: :unlike
    get "viewed_users", on: :member
    get "liked_users",  on: :member

    resources :comments, only: [:create] do
      post "like", on: :member
      delete "like", on: :member, action: :unlike
      resources :replies, only: [:create] do
        post "like", on: :member
        delete "like", on: :member, action: :unlike
      end
    end

    scope :module => "projects" do
      resources :screenshots
      resources :memberships, :only => [ :index, :show, :create, :destroy ]
    end
    member do
      get 'edit_screenshots'
      get 'edit_team'
      get 'edit_opensource'
    end
  end

  resources :screenshots

  resources :submissions do
    resources :votes
  end

  resources :platforms
  resources :votes
  resources :organizations do
    member do
      get 'edit_team'
    end
  end

  resources :activities
  resources :invitations
  resources :conversations do
    member do
      delete :leave
    end
    resources :messages
  end
  resources :contests
  resources :hr_scores
  resource :search do
    collection do
      get :events
      get :network
      get :projects
      get :organizations
    end
  end

  root to: 'home#index'
  match '*catchall', to: 'application#raise_not_found!'
end
