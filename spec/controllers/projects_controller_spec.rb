require 'spec_helper'

describe ProjectsController do
  let(:user)    { FactoryGirl.create(:user)    }
  let(:project) { FactoryGirl.create(:project) }

  describe "GET #index" do

    it "responds successfully" do
      get :index
      expect(response).to be_success
    end

    it "responds successfully for JS" do
      get :index, :format => :js
      expect(response).to be_success
    end

    it "loads projects" do
      prj1, prj2 = create(:project), create(:project)
      get :index, :format => :json
      assigns(:projects).should match_array(Project.all)
      response.should be_success
    end

    context "with filters" do
      let(:launch)    { create(:event    , :title => "Launch Hackathon") }
      let(:angelhack) { create(:event    , :title => "AngelHack") }
      let(:bridge)    { create(:project  , :title => "Bridge") }
      let(:js)        { create(:platform , :title => "js") }
      let(:ruby)      { create(:platform , :title => "ruby") }
      let(:gempad)    { create(:project  , :title => "Gempad") }

      before do
        gempad.platforms << ruby
        bridge.platforms << js
        angelhack.projects << gempad
        launch.projects << gempad
        launch.projects << bridge
      end

      it "reutrns all when blank" do
        get :index, :term => " ", :platform_ids => [ " "], :event_ids => [" "]
        assigns(:projects).should match_array [ gempad, bridge ]
      end

      it "returns projects for platforms" do
        get :index, :platform_ids => [ js.id ]
        assigns(:projects).should == [bridge]
      end

      it "returns projects for event" do
        get :index, :event_ids => [ launch.id ]
        assigns(:projects).should == [ bridge, gempad ]
      end

      it "returns projects for term" do
        get :index, :term => gempad.title
        assigns(:projects).should == [ gempad ]
      end

      it "returns projects for term, platform and event" do
        get :index, :term => gempad.title, :platform_ids => [ ruby.id ], :event_id => [ launch.id ]
        assigns(:projects).should == [ gempad ]
      end

	  it "returns projects for term, platform" do
		  get :index, :term => gempad.title, :platform_ids => [ruby.id]
		  assigns(:projects).should == [ gempad ]
		end
	  it "returns projects for term, event" do
		  get :index, term: gempad.title, event_ids: [ angelhack.id ]
		  assigns(:projects).should == [ gempad ]
	  end
    end
  end

  describe "GET #show" do
    it "assigns @project with project" do
      get :show, :id => project.id, :format => :json
      assigns(:project).should == project
      response.should be_success
    end
  end

  describe "PUT #update" do

    before do
      signin(user)
      user.projects << project
    end

    it "updates the project" do
      platform = FactoryGirl.create(:platform)
      put :update, :id => project.id,
        :format => :json,
        :project => { :title => "update",
                      :video_url => 'http://youtube.com/sample',
                      :platform_ids => [ platform.id ] }
      assigns(:project).title.should == "update"
      expect { project.reload }.to change { project.updated_at }
      project.platforms.should include platform
      response.should be_success
    end
  end
end
