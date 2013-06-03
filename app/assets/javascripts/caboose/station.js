
var CabooseStation = function() {};

CabooseStation = Class.extend({
    conductor: false,
    state: 'min', // left, right, or min
    open_tabs: [], // Currently open tabs
    
    init: function()
    {       
      this.attach_dom();
      //alert(this.open_tabs);

      if ($('#caboose_station').hasClass('state_left'))
      {
        $('#caboose_station').css('left', 0);
        $('#caboose_station').show();
        this.state = 'left';
      }
      else if ($('#caboose_station').hasClass('state_right'))
      {
        $('#caboose_station').css('right', 0);
        $('#caboose_station').show();
        this.state = 'right';
      }
      else
      {
        $('#caboose_station').hide();
        this.state = 'min';
      }
    },
    
    attach_dom: function()
    {
      var this2 = this;
      $('#caboose_station li ul.visible').each(function (i,ul) {
        var id = $(this).parent().attr('id').replace('nav_item_', '');
        this2.open_tabs[this2.open_tabs.length] = id;
      });
      
      $('#caboose_conductor').click(function() { this2.open(); });  
      $('#caboose_station ul.hidden').hide();
      $('#caboose_station li a.top_level').click(function() {
        ul = $(this).parent().children("ul.hidden:first");
        var id = $(this).parent().attr('id').replace('nav_item_', '');
        if (ul.length)
        {
          ul.slideDown(200).addClass('visible').removeClass('hidden');
          this2.open_tabs[this2.open_tabs.length] = id; 
        }
        else
        {
          ul = $(this).parent().children("ul:first");
          ul.hide().addClass('hidden').removeClass('visible');
          
          var index = this2.open_tabs.indexOf(id);
          if (index > -1)
            this2.open_tabs.splice(index, 1);
        }
      });      
      $('#caboose_station li ul a').each(function(i, a) {
        var href = $(a).attr('href');
        $(a).click(function(event) {
          event.preventDefault();
          this2.open_url(href); 
        })
      });      
      $('#caboose_station a.close').click(function(event) {
        event.preventDefault();
        
        if (this2.state == 'left')
          this2.close_url($(this).attr('href'));
        else if (this2.state == 'right')
          this2.min();
      });
    },
    
    min: function()
    {
      if (this.state == 'min')
        return;
      if (this.state == 'right')
      {
        $('#caboose_station').hide('slide', { direction: 'right' }, 300);
      }
      else if (this.state == 'left')
      {
        var w = $(window).width();
        $('#caboose_station').animate({ left: '+=' + w }, 300);
      }
      this.state = 'min';
    },
    
    left: function(func_after)
    {
      if (this.state == 'left')
        return;
      if (!func_after)
        func_after = function() {};      
      if (this.state == 'right')
      {
        var w = $(window).width() - $('#caboose_station').width();
        $('#caboose_station').animate({ left: '-=' + w }, 300, func_after);
      }
      else if (this.state == 'min')
      {
        var w = $(window).width();
        $('#caboose_station').animate({ left: '+=' + w }, 300, func_after);
      }
      this.state = 'left'; 
    },
    
    right: function(func_after)
    {
      if (this.state == 'right')
        return;
      if (!func_after)
        func_after = function() {};
      if (this.state == 'left')
      {
        var w = $(window).width() - $('#caboose_station').width();
        $('#caboose_station').animate({ left: '+=' + w }, 300, func_after);
      }
      else if (this.state == 'min')
      {
        $('#caboose_station').show('slide', { direction: 'right' }, 300, func_after);        
      }
      this.state = 'right'; 
    },
    
    open: function() 
    {
      if (this.state == 'min')
        this.right();
      else if (this.state == 'right')
        this.left();
    },
    
    close: function() 
    {
      if (this.state == 'min')
        return;
      if (this.state == 'left')
        this.right();
      else if (this.state == 'right');
        this.min();      
    },
    
    open_url: function(url)
    {      
      // Send the station settings first
      var this2 = this;
      $.ajax({
        url: '/admin/station',
        type: 'put',
        data: {
          state: 'left',
          open_tabs: this2.open_tabs,
          return_url: window.location.pathname
        },
        success: function() {
          if (this2.state == 'left')
          {
            window.location = url;
            return;
          }
          
          var w = $(window).width() - $('#caboose_station').width();
          var h = $(window).height();
          
          $('#caboose_station').after(
            $('<div/>')
              .attr('id', 'caboose_white')
              .css({
                position: 'absolute',
                right: -1,
                top: 0,
                width: 1,
                height: h,
                background: 'url(/assets/loading.gif) 40px 40px no-repeat #fff'
              })
            );
          $('#caboose_station').removeClass('state_right').addClass('state_left');
          $('#caboose_station').animate({ left: '-=' + w }, 300, function() {
            //$.ajax({
            //  url: url,
            //  success: function(html) { window.location = url; }
            //});
            window.location = url; 
          });
          $('#caboose_white').animate({ width: '+=' + w }, 300);
        }
      });
    },
    
    close_url: function(url)
    {      
      // Send the station settings first
      var this2 = this;
      $.ajax({
        url: '/admin/station',
        type: 'put',
        data: {
          state: 'right',
          open_tabs: this2.open_tabs,
          return_url: false
        },
        success: function() {
          var w = $(window).width() - $('#caboose_station').width();
          $('#caboose_station').removeClass('state_left').addClass('state_right');
          $('#content_wrapper').animate({ marginLeft: '+=' + w }, 300);
          $('#caboose_station').animate({ left: '+=' + w }, 300, function() { window.location = url; })
        }
      }); 
    }
});

/******************************************************************************/

var caboose_station = false;
$(document).ready(function() {
  caboose_station = new CabooseStation();
});