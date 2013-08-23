
BoundCheckbox = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  message: false,
  placeholder: false,
 
  init: function(params) {
    
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
    this.message = this.el + '_message';
    this.placeholder = this.el + '_placeholder';
    
    var this2 = this;
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    if (this.attribute.fixed_placeholder)
    {
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.placeholder)
        .addClass('placeholder')
        .append($('<span/>').html(this.attribute.nice_name + ': '))
      );
    }
    var cb = $('<input/>')
      .attr('id', this.el)
      .attr('type', 'checkbox')
      .addClass('caboose_bound_input')
      .css('left', $('#'+this.placeholder).outerWidth() + 10)
      .attr('checked', this.attribute.value)
      .on('change', function() {        
        this2.save(); 
      });
    if (this.attribute.align == 'right')
      cb.css('left', this.attribute.width - 10)
    else if (this.attribute.align == 'center')
      cb.css('left', Math.floor($('#'+this.el+'_container').outerWidth()/2))
    else // left
      cb.css('left', $('#'+this.placeholder).outerWidth() + 10)
    $('#'+this.el+'_container').append(cb);
    
    $('#'+this.el+'_container').append($('<input/>')
      .attr('type', 'text')
      .attr('id', this.el + '_background')
      .attr('disabled', true)
      //.css('background', '#fff')
      .addClass('checkbox_background')
    );
    if (this.attribute.width)
      $('#'+this.el+'_background').css('width' , this.attribute.width);
  },
  
  view: function() {
    
  },
    
  edit: function() {
    
  },
  
  save: function() {
    
    this.attribute.value = $('#'+this.el).prop('checked') ? 1 : 0;
        
    var this2 = this;
    this.model.save(this.attribute, function(resp) {
      $('#'+this2.el+'_check a').removeClass('loading');
      if (resp.error) this2.error(resp.error);
      else
      {
        if (this2.binder.success)
          this2.binder.success(this2);
        this2.view();
      }
    });
  },
  
  cancel: function() {
    this.attribute.value = this.attribute.value_clean;
    $('#'+this.el).attr('checked', '' + this.attribute.value ? 'true' : 'false') 
    this.view();
  },

  error: function(str) {
    if (!$('#'+this.message).length)
      $('#'+this.el+'_container').prepend($('<div/>').attr('id', this.message));
    $('#'+this.message).html("<p class='note error'>" + str + "</p>");
  }

});
