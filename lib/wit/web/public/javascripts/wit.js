
var WIT = {};

WIT.THINK_URL = "/~";
WIT.EDIT_URL = "/~/edit";

WIT.Transaction = function () {
  this.actions = [];
};

WIT.Transaction.prototype.proceed = function () {
  var next = this.actions.shift();
  if (!next) {
    console.log("No more action!");
    return;
  }

  next(this);
};

WIT.Transaction.prototype.then = WIT.Transaction.prototype.will = function(action) {
  this.actions.push(action);
  return this;
};

WIT.Store = function() {
  this.state = null;
  this.on = {
    didCreate: $.Callbacks(),
    willSave: $.Callbacks(),
    didSave: $.Callbacks(),
    didSync: $.Callbacks(),
    didLoad: $.Callbacks(),
    didChangeState: $.Callbacks()
  };
};

WIT.Store.makeNoteURL = function(path) {
  var currentURL = path;
  var plainURL = currentURL.replace(WIT.EDIT_URL, "");
  if (!plainURL.length)
    return null;
  return WIT.THINK_URL + plainURL;
};

WIT.Store.prototype.willSave = function(values) {
  if (this.isSaving()) {
    console.log("A transaction is on flight. canceling."); // FIXME: Should be done in a callback.
    return false;
  }

  if (!values.body.length) {
    window.alert("You have nothing to save!"); // FIXME: Should be callback
    return false;
  }

  this.on.willSave.fire();
  return true;
};

WIT.Store.prototype.isSaving = function(tx) {
  return this.state != null;
};

WIT.Store.prototype.setState = function(state) {
  console.log("State:" + state);
  this.state = state;
  this.on.didChangeState.fire();
};

WIT.Store.prototype.doCreate = function(tx) {
  this.setState("creating");
  $.ajax({
    url: "/~/fresh",
    contentType: "application/json",
    type: "POST",
    dataType: "json",
    data: JSON.stringify({ title: tx.post.title })
  }).done(function(data) {
    this.setState(null);
    this.on.didCreate.fire(data);
    tx.url = data.url;
    tx.proceed();
   }.bind(this));
};

WIT.Store.prototype.doSave = function(tx) {
  this.setState("saving");
  $.ajax({
    url: tx.url,
    contentType: "application/json",
    type: "PUT",
    dataType: "json",
    data: JSON.stringify({ publish: tx.post.publish, body: tx.post.body })
  }).done(function(data) {
    this.setState(null);
    this.on.didSave.fire();
    tx.proceed();
  }.bind(this));
};

WIT.Store.prototype.doSync = function(tx) {
  this.setState("syncing");
  $.ajax({
    url: "/sync",
    contentType: "application/json",
    type: "POST",
    data: JSON.stringify({})
  }).done(function(data) {
    this.setState(null);
    this.on.didSync.fire(data);
    tx.proceed();
  }.bind(this));
};

WIT.Store.prototype.loadNote = function(url) {
  $.ajax({
    url: url,
    contentType: "application/json",
    type: "GET",
    dataType: "json"
  }).done(function(data) {
    this.on.didLoad.fire(data);
  }.bind(this));
};

WIT.Store.prototype.save = function(noteUrl, values) {
  if (!this.willSave(values))
    return;

  var tx = new WIT.Transaction();
  tx.post = values; // FIXME: should be folded into Transaction ctor.
  if (!noteUrl)
    tx.will(this.doCreate.bind(this));
  else
    tx.url = noteUrl;
  tx.will(this.doSave.bind(this))
    .then(this.doSync.bind(this))
    .proceed();
};

WIT.store = new WIT.Store();

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

WIT.didCreate = function(values) {
  WIT.didGetNoteURL(values.url);
};

WIT.didGetNoteURL = function(noteUrl) {
  WIT.noteUrl = noteUrl;
  var editURL = WIT.EDIT_URL + noteUrl.replace(WIT.THINK_URL, "");
  if (window.location.pathname != editURL)
    window.history.pushState({}, null, editURL);
  $(".edit-link-anchor").attr("href", noteUrl);
};

WIT.willSave = function() {
};

WIT.didSave = function() {
  $(".edit-body").focus();
};

WIT.didChangeStoreState = function() {
  if (WIT.store.isSaving())
    $(".edit-save").addClass("saving");
  else
    $(".edit-save").removeClass("saving");
};

WIT.didSync = function() {
};

WIT.didLoad = function(values) {
  WIT.fill(values);
};

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

WIT.save = function() {
  WIT.store.save(WIT.postURL, WIT.populate());
};

WIT.init = function() {
  // FIXME: focus .edit-body if there is any title given.
  $(".edit-title").focus();
  $(".edit-body").on("focus", WIT.setupBodyEditing);
  $(".edit-save").on("DOMActivate", WIT.save);
  
  WIT.store.on.didCreate.add(WIT.didCreate);
  WIT.store.on.willSave.add(WIT.willSave);
  WIT.store.on.didSave.add(WIT.didSave);
  WIT.store.on.didSync.add(WIT.didSync);
  WIT.store.on.didLoad.add(WIT.didLoad);
  WIT.store.on.didChangeState.add(WIT.didChangeStoreState);

  var noteURL = WIT.Store.makeNoteURL(window.location.pathname);
  if (noteURL) {
    WIT.didGetNoteURL(noteURL);
    WIT.store.loadNote(noteURL);
  }
};

$(document).on("ready", WIT.init);