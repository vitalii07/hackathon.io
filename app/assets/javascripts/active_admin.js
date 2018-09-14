//= require active_admin/base


$( document ).ready(function() {

  // when the events page is loaded
  if ($("body.admin_events").length > 0) {
    // hide the region filter when loading the events page at first
    $("#q_region").parent().hide();

    // populate dynamically when change the country in the country filter
    $("#q_country").change(function() {
      var country = $( "#q_country option:selected" ).text();
      // if select "Any", hide the region filter
      if (country == "Any") {
        $("#q_region").empty();
        $("#q_region").parent().hide();
      }
      // if not select "Any", show the region filter and populate the regions based on the selected country
      else {
        $("#q_region").parent().show();
        $.ajax({
  		  type: 'GET',
  		  url: "/admin/events/event_regions",
  		  data: { country: country},
  		  dataType: 'json',
  		  success: function (data) {
  		    $("#q_region").empty();
  		    $.each(data.events, function(index, value) {
  	          $('#q_region').append($('<option>').text(value).val(value));
  	        });
  	      }
  	    }); 
      }    
    });
  }  
});
