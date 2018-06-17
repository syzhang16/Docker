$(function() {

    /**
    * Get the list of tags by id
    * @param {String} tag|contact
    * @return {Array} Array of tags [val => text]
    */
    var getTagsList = function(selector) {
        var tags = new Array(), that;
	selector = selector.indexOf('#') == -1 ? '#' + selector : selector;
        $(selector).each(function(i) {
            that = $(this);
	    if (that.text() == undefined) { return; }
            tags[that.val()] = that.text();
        });
        return tags;
    };

    /* Init */
    var initial_tags = getTagsList('tag option'), initial_tags_contact = getTagsList('contact_tag option');

    /* Adding a tag to a Contact Handler */
    $("#contact_add_tag").click(function() {
        var tags = getTagsList('tag option:selected'), contact_tagHTML = $('#contact_tag');
        console.log(tags);
	for (var key in tags) {
	    if (tags[key])
		contact_tagHTML.append(
		    corm.createHTML('option', {
			content: tags[key],
			value: key
		    })
		);
	}
	$('#tag option:selected').remove();
    });

  /* Remove a tag from the Contact tag list */
  $("#contact_remove_tag").click(function() {
    var tags = getTagsList('contact_tag option:selected'), tagHTML = $('#tag');
    for (var key in tags) {
	if (tags[key])
	    tagHTML.append(
		corm.createHTML('option', {
		    content: tags[key],
		    value: key
		})
	    );
    }
    $('#contact_tag option:selected').remove();
  });

  /* Remove from the Tags list, tags which are already linked to the contact */
  $("#contact_add_button").click(function() {
    var tags = getTagsList('select#contact_tag option');
    for (var key in tags){
	$('#tag option[value="' + key + '"]').remove();
    }
  });

  /* Get all tags linked to the contact in the modal window and add it to the main form for edition/creation */
  $("#contact_submit_add").click(function() {
    var tags = getTagsList('select#contact_tag option');
    /* Empty the list of tags in the main form for creation/edition */
    var main_form_select_tags = $('#display_contact_tag');
    main_form_select_tags.html('');
    for (var key in tags) {
      if (tags[key]) {
	main_form_select_tags.append(
	    corm.createHTML('option', {
		content: tags[key],
		value: key,
		selected: 'selected'
	    })
	);
      }
    }
    initial_tags = getTagsList('select#tag option');
    initial_tags_contact = tags.slice(0);
  });

  /* Manage cancellation */
  $("#contact_cancel_add").click(function() {
    var contact_tagHTML = $('select#contact_tag'), tagHTML = $('select#tag'), key;
    contact_tagHTML.html('');
    tagHTML.html('');
    for (key in initial_tags_contact) {
	contact_tagHTML.append(
	    corm.createHTML('option', {
		content: initial_tags_contact[key],
		value: key
	    })
	);
    }
    for (key in initial_tags) {
	tagHTML.append(
	    corm.createHTML('option', {
		content: initial_tags[key],
		value: key
	    })
	);
    }
  });

  /* Check before submit */
  $("#contact_submit_form").click(function(e) {
    var select = $('select#display_contact_tag');
    /* Be sure the select field is not disabled */
    select.attr('disabled',false);
    select.find('option').each(function() {
        $(this).attr('selected', 'selected');
    });
  });

});
