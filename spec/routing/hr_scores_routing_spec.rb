require "spec_helper"

describe HrScoresController do
  describe "routing" do

    it "routes to #index" do
      get("/hr_scores").should route_to("hr_scores#index")
    end

    it "routes to #new" do
      get("/hr_scores/new").should route_to("hr_scores#new")
    end

    it "routes to #show" do
      get("/hr_scores/1").should route_to("hr_scores#show", :id => "1")
    end

    it "routes to #edit" do
      get("/hr_scores/1/edit").should route_to("hr_scores#edit", :id => "1")
    end

    it "routes to #create" do
      post("/hr_scores").should route_to("hr_scores#create")
    end

    it "routes to #update" do
      put("/hr_scores/1").should route_to("hr_scores#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/hr_scores/1").should route_to("hr_scores#destroy", :id => "1")
    end

  end
end
