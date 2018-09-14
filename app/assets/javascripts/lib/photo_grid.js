/*
    Gallery Grid Main Script
    (c) 2013 bdwm.be
    For any questions please email me at jules@bdwm.be
    Version: 1.3
*/
var rgg_params = [{
"type":"rgg", "margin":9, "maxrowheight":400, "intime":100, "outtime":100, "captions":"title"},
{
"type":"rgg", "margin":9, "maxrowheight":400,"intime":100,"outtime":100,"captions":"title"},
{
"type":"rgg", "margin":9, "maxrowheight":400,"intime":100,"outtime":100,"captions":"title"},
{
"type":"rgg", "margin":9, "maxrowheight":400,"intime":100,"outtime":100,"captions":"title"}];

var mobile =  /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent);
var scale = parseFloat(rgg_params[0].scale) || 1.0;
var intime = parseFloat(rgg_params[0].intime) || 100;
var outtime = parseFloat(rgg_params[0].outtime) || 100;

jQuery(document).ready(function(){
  if(!mobile) {

      // create copies from the images as placeholders to be used by imagegrid
      jQuery('.rgg_imagegrid img').each(function() {
          var $this = jQuery(this);
          var offset = $this.position();
          $this.clone().addClass('bbg_placeholder').css({ visibility : 'hidden' }).appendTo($this.parent());
          $this.css({ left:offset.left, top:offset.top, position: 'absolute', 'max-width' : 'none' }).addClass('bbg_img');
      });

      jQuery('.rgg_imagegrid').each(function() {

          $this = jQuery(this);
          var id = parseInt($this.attr('rgg_id'));
          var p = rgg_params[id-1];
          p.scale = parseFloat(p.scale) || 1.0;

          jQuery('.bbg_img', this).each(function() {
             // TODO: save all calculated values in array, each time the window is resized.
          });

          jQuery('.bbg_img', this).mouseenter(function() {
            var offsetinfo = $(this).position();
            $(".js-image-info").hide();

            $(this).next('span').width($(this).width()).height($(this).height()).css({ left:offsetinfo.left, top:offsetinfo.top }).show();
            $(this).next('span').mouseleave(function() {
              $(this).hide();
            });
          });
      });

  } else {

      // if mobile
      jQuery('.rgg_imagegrid img').addClass('bbg_placeholder');
  }

  jQuery('.rgg_imagegrid').each(function() {
      $this = jQuery(this);
      var id = parseInt($this.attr('rgg_id'));
      var p = rgg_params[id-1];

      $this.gallerygrid({
          'maxrowheight' :  parseInt(p.maxrowheight) || 20,
          'margin' :        parseInt(p.margin) || 0,
          'items' : '.bbg_placeholder',
          'after_init' : function() { },
          'before' : function() { },
          'after' : function() {
              if (!mobile) {
                  jQuery('.bbg_placeholder').each(function() {
                      // update position of the absolute clones based on their sibling placeholder
                      $placeholder = jQuery(this);
                      $clone = $placeholder.siblings('.bbg_img').eq(0);
                      var offset = $placeholder.position();

                      $clone.css({ left:offset.left, top:offset.top, position: 'absolute', width: $placeholder.width(), height: $placeholder.height() }).addClass('bbg_image');
                  });
              }
          }
      });
  });

});
