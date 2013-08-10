
var WIT = {};

WIT.populate = function() {
  var body = $(".edit-body").val();
  var title = $(".edit-title").val();
  var publish = $(".edit-publish").prop("checked");
  return { body: body, title: title, publish: publish };
};

WIT.fill = function(data) {
  $(".edit-body").val(data.body);
  $(".edit-title").val(data.title);
  $(".edit-publish").prop("checked", data.publish);
};

WIT.EDIT_URL = "/~/edit";
WIT.THINK_URL = "/~";

WIT.makeNoteURL = function() {
  var currentURL = window.location.pathname;
  var plainURL = currentURL.replace(WIT.EDIT_URL, "");
  if (!plainURL.length)
    return null;
  return WIT.THINK_URL + plainURL;
};

WIT.makeMDTitle = function(title) {
  return [title, title.replace(/./g, "="), ""].join("\n");
};

WIT.setupBodyEditing = function() {
  var bodyEl = $(".edit-body");
  var body = bodyEl.val();
  if (body.length)
    return;
  var titleEl = $(".edit-title");
  var title = titleEl.val();
  if (!title.length)
    return;
  var boilerplate = WIT.makeMDTitle(title);
  bodyEl.val(boilerplate);
  window.requestAnimationFrame(function() {
    bodyEl[0].selectionStart = bodyEl[0].selectionEnd = boilerplate.length;
  });
};

WIT.save = function() {
  if (!WIT.willSave()) {
    // FIXME: say something to user.
    console.log("A transaction is on flight. canceling.");
    return;
  }

  var values = WIT.populate();
  if (!values.body.length) {
    window.alert("You have nothing to save!");
    return;
  }

  var url = window.location.pathname;
  if (url != WIT.EDIT_URL) {
    WIT.saveOn(url);
    return;
  }

  $.ajax({
    url: "/~/fresh",
    contentType: "application/json",
    type: "POST",
    dataType: "json",
    data: JSON.stringify({ title: values.title })
  }).done(function(data) {
    WIT.didGetNoteURL(data.url);
    WIT.saveOn(data.url);
  });

  return;
};

WIT.loadNote = function(url) {
  $.ajax({
    url: url,
    contentType: "application/json",
    type: "GET",
    dataType: "json",
  }).done(function(data) {
    WIT.fill(data);
  });
};

WIT.didGetNoteURL = function(noteUrl) {
  var editURL = WIT.EDIT_URL + noteUrl.replace(WIT.THINK_URL, "");
  if (window.location.pathname != editURL)
    window.history.pushState({}, null, editURL);
  $(".edit-link-anchor").attr("href", noteUrl);
};

WIT.willSave = function() {
  if (WIT.saving)
    return false;
    
  WIT.saving = true;
  $(".edit-save").addClass("saving");
  return true;
};

WIT.didSave = function() {
  $(".edit-body").focus();
}

WIT.didSync = function() {
  WIT.saving = false;
  $(".edit-save").removeClass("saving");
};

WIT.saveOn = function(url) {
  var u = WIT.makeNoteURL();
  var values = WIT.populate();

  $.ajax({
    url: u,
    contentType: "application/json",
    type: "PUT",
    dataType: "json",
    data: JSON.stringify({ publish: values.publish, body: values.body })
  }).done(function(data) {
    WIT.didSave();
    WIT.sync();
  });
};

WIT.sync = function() {
  $.ajax({
    url: "/sync",
    contentType: "application/json",
    type: "POST",
    data: JSON.stringify({})
  }).done(function(data) {
    // FIXME: notify somehow.
    WIT.didSync();
  });
};

WIT.init = function() {
  // FIXME: focus .edit-body if there is any title given.
  $(".edit-title").focus();
  $(".edit-body").on("focus", WIT.setupBodyEditing);
  $(".edit-save").on("DOMActivate", WIT.save);
  
  var noteURL = WIT.makeNoteURL();
  if (noteURL) {
    WIT.didGetNoteURL(noteURL);
    WIT.loadNote(noteURL);
  }
};

$(document).on("ready", WIT.init);