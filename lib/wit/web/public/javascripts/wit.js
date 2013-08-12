
var WIT = {};

WIT.THINK_URL = "/~";
WIT.EDIT_URL = "/~/edit";
WIT.AUTOSAVE_INTERVAL = 3000;

WIT.makeMDTitle = function(title) {
  return [title, title.replace(/./g, "="), ""].join("\n");
};

WIT.makeNoteURL = function(path) {
  var currentURL = path;
  var plainURL = currentURL.replace(WIT.EDIT_URL, "");
  if (!plainURL.length)
    return null;
  return WIT.THINK_URL + plainURL;
};

WIT.tell = function(message) {
  $(".think-footer-console").text(message);
};

//
// Transaction
//

WIT.Transaction = function () {
  this.actions = [];
};

WIT.Transaction.proceedFromEmpty = function() {
  return (new WIT.Transaction()).proceed();
};

WIT.Transaction.prototype.proceed = function () {
  window.requestAnimationFrame(function() {
    var next = this.actions.shift();
    if (next)
      next(this);
  }.bind(this));
  return this;
};

WIT.Transaction.prototype.then = WIT.Transaction.prototype.will = function(action) {
  this.actions.push(action);
  return this;
};

//
// Store
//

WIT.Store = function() {
  this.state = null;
  this.on = {
    didCreate: $.Callbacks(),
    willSave: $.Callbacks(),
    didSave: $.Callbacks(),
    willSync: $.Callbacks(),
    didSync: $.Callbacks(),
    didLoad: $.Callbacks(),
    didChangeState: $.Callbacks()
  };
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
  this.on.willSync.fire();
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

WIT.Store.prototype.save = function(noteURL, values, options) {
  if (!this.willSave(values))
    return null;

  var tx = new WIT.Transaction();
  tx.post = values; // FIXME: should be folded into Transaction ctor.
  if (!noteURL)
    tx.will(this.doCreate.bind(this));
  else
    tx.url = noteURL;
  tx.will(this.doSave.bind(this));
  if (!options.nosync)
    tx.then(this.doSync.bind(this));
  return tx.proceed();
};

WIT.Store.prototype.sync = function() {
  var tx = new WIT.Transaction();
  tx.will(this.doSync.bind(this));
  return tx.proceed();
};

WIT.Idler = function(el, interval) {
  this.interval = interval;
  this.active = false;
  this.el = el;
  this.el.on("keydown", function(evt) {
    this.ping();
  }.bind(this));

  this.on = {
    didIdle: $.Callbacks()
  };
};

//
// Idler
//

WIT.Idler.prototype.getTime = function() {
  return (new Date()).getTime();
};

WIT.Idler.prototype.ping = function(pingTime) {
  this.pingTime = pingTime || this.getTime();
  if (this.active)
    return;
  this.active = true;
  window.setTimeout(function() {
    this.active = false;
    var passed = this.getTime() - this.pingTime;
    if (passed < this.interval) {
      this.ping(this.pingTime);
      return;
    }

    this.didIdle();
  }.bind(this), this.interval - (this.getTime() - pingTime));
};

WIT.Idler.prototype.didIdle = function() {
  this.on.didIdle.fire();
};

//
// Shortcut
//
WIT.Shortcut = function(el) {
  this.el = el;
  this.el.on("keydown", this.didType.bind(this));
  this.table = {}
};

WIT.Shortcut.prototype.add = function(key, meta, callback) {
  this.table[key] = { meta: meta, callback: callback };
};

WIT.Shortcut.prototype.didType = function(evt) {
  var code = String.fromCharCode(evt.keyCode); // FIXME: Should avoid instantiation.
  var entry = this.table[code];
  if (!entry || evt.metaKey != entry.meta)
    return;
  entry.callback();
  evt.preventDefault();
  evt.stopPropagation();
};

//
// Editor
//

WIT.Editor = function() {
  this.titleEl = $(".edit-title");
  this.bodyEl = $(".edit-body");
  this.saveEl = $(".edit-save");
  this.publishEl = $(".edit-publish");
  this.noteLinkEl = $(".edit-link-anchor");

  this.titleEl.on("input", this.didEdit.bind(this));
  this.bodyEl.on("focus", this.setupBodyEditing.bind(this)).on("input", this.didEdit.bind(this));
  this.saveEl.on("DOMActivate", this.save.bind(this));
  this.publishEl.on("click", this.confirmPublish.bind(this));

  this.store = new WIT.Store();
  this.store.on.didCreate.add(this.didCreate.bind(this));
  this.store.on.willSave.add(this.willSave.bind(this));
  this.store.on.didSave.add(this.didSave.bind(this));
  this.store.on.willSync.add(this.willSync.bind(this));
  this.store.on.didSync.add(this.didSync.bind(this));
  this.store.on.didLoad.add(this.didLoad.bind(this));
  this.store.on.didChangeState.add(this.didChangeStoreState.bind(this));

  this.idler = new WIT.Idler($(document.body), WIT.AUTOSAVE_INTERVAL);
  this.idler.on.didIdle.add(this.autosave.bind(this));
  this.idler.ping();

  this.shortcut = new WIT.Shortcut($(document.body));
  this.shortcut.add("S", true, this.save.bind(this));
  this.shortcut.add("X", true, this.moveToNote.bind(this));
  this.shortcut.add("E", true, this.preview.bind(this));

  var noteURL = WIT.makeNoteURL(window.location.pathname);
  if (noteURL) {
    this.didGetNoteURL(noteURL);
    this.store.loadNote(noteURL);
  } else {
    this.titleEl.focus();
  }
};

WIT.Editor.prototype.setupBodyEditing = function() {
  var body = this.bodyEl.val();
  if (body.length)
    return;
  var title = this.titleEl.val();
  if (!title.length)
    return;
  var boilerplate = WIT.makeMDTitle(title);
  this.bodyEl.val(boilerplate);
  window.requestAnimationFrame(function() {
    this.bodyEl[0].selectionStart = this.bodyEl[0].selectionEnd = boilerplate.length;
  }.bind(this));
};

WIT.Editor.prototype.didCreate = function(values) {
  this.didGetNoteURL(values.url);
};

WIT.Editor.prototype.didGetNoteURL = function(noteURL) {
  this.noteURL = noteURL;
  this.noteLinkEl.attr("href", noteURL);

  var editURL = WIT.EDIT_URL + noteURL.replace(WIT.THINK_URL, "");
  if (window.location.pathname != editURL)
    window.history.pushState({}, null, editURL);
};

WIT.Editor.prototype.moveToNote = function() {
  var link = this.noteLinkEl.attr("href");
  if (link.length)
    window.location = link;
};

WIT.Editor.prototype.willSave = function() {
  WIT.tell("Saving...");
};

WIT.Editor.prototype.didSave = function() {
  WIT.tell("Saved.");
  this.bodyEl.focus();
};

WIT.Editor.prototype.didChangeStoreState = function() {
  if (this.store.isSaving())
    this.saveEl.addClass("saving");
  else
    this.saveEl.removeClass("saving");
};

WIT.Editor.prototype.willSync = function() {
  WIT.tell("Syncing...");
};

WIT.Editor.prototype.didSync = function() {
  this.moveToNote();
};

WIT.Editor.prototype.didLoad = function(values) {
  this.fill(values);
  this.titleEl.focus();
};

WIT.Editor.prototype.didEdit = function() {
  this.dirty = true;
  this.bodyEl.addClass("edit-dirty");
};

WIT.Editor.prototype.populate = function() {
  var body = this.bodyEl.val();
  var title = this.titleEl.val();
  var publish = this.publishEl.prop("checked");
  return { body: body, title: title, publish: publish };
};

WIT.Editor.prototype.fill = function(data) {
  this.bodyEl.val(data.body);
  this.titleEl.val(data.title);
  this.publishEl.prop("checked", data.publish);
};

WIT.Editor.prototype.save = function() {
  return this.store.save(this.noteURL, this.populate(), {});
};

WIT.Editor.prototype.autosave = function() {
  if (!this.populate().body.length)
    return WIT.Transaction.proceedFromEmpty();
  if (!this.bodyEl.hasClass("edit-dirty"))
    return WIT.Transaction.proceedFromEmpty();
  this.bodyEl.removeClass("edit-dirty");
  return this.store.save(this.noteURL, this.populate(), { nosync: true });
};

WIT.Editor.prototype.preview = function() {
  this.autosave().then(function(tx) {
    this.moveToNote();
    tx.proceed();
  }.bind(this));
};

WIT.Editor.prototype.confirmPublish = function(evt) {
  // "checked" proeprty becomes true BEFORE the default action is cancelled and
  // undo-ed when it is prevented! Bad Web!
  if (evt.target.checked && !window.confirm("Do you publish?")) {
    evt.preventDefault();
    return false;
  }

  return true;
};

//
// IndexView
//

WIT.IndexView = function() {
  $(".index-nav-new").on("DOMActivate", this.newNote.bind(this));
  $(".index-nav-sync").on("DOMActivate", this.sync.bind(this));
  this.store = new WIT.Store();
  this.store.on.didSync.add(this.didSync.bind(this));
};

WIT.IndexView.prototype.newNote = function() {
  window.location = WIT.EDIT_URL;
};

WIT.IndexView.prototype.sync = function() {
  this.store.sync();
  WIT.tell("Syncing...");
};

WIT.IndexView.prototype.didSync = function() {
  WIT.tell("Sync done.");
};

//
// NoteNav
//
WIT.NoteView = function() {
  this.editLinkEl = $(".edit-link-anchor");
  this.newLinkEl = $(".new-link-anchor");
  this.nextLinkEl = $("#next-link");
  this.prevLinkEl = $("#prev-link");
  this.shortcut = new WIT.Shortcut($(document.body));
  this.shortcut.add("E", true, this.moveToRef.bind(this, this.editLinkEl));
  this.shortcut.add("O", true, this.moveToRef.bind(this, this.newLinkEl));
  this.shortcut.add("J", false, this.moveToRef.bind(this, this.nextLinkEl));
  this.shortcut.add("K", false, this.moveToRef.bind(this, this.prevLinkEl));
};

WIT.NoteView.prototype.moveToRef = function(ref) {
  var dest = ref.prop("href");
  console.log(dest);
  if (dest)
    window.location = dest;
};

// Bootstrap
//
WIT.initEditing = function() {
  WIT.editor = new WIT.Editor();
};

WIT.initNoteView = function() {
  WIT.noteView = new WIT.NoteView();
};

WIT.initIndexView = function() {
  WIT.indexView = new WIT.IndexView();
};

