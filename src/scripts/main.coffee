class FormbuilderModel extends Backbone.DeepModel
  sync: -> # noop
  indexInDOM: ->
    $wrapper = $(".fb-field-wrapper").filter ( (_, el) => $(el).data('cid') == @cid  )
    $(".fb-field-wrapper").index $wrapper
  is_input: ->
    Formbuilder.inputFields[@get(Formbuilder.options.mappings.FIELD_TYPE)]?
  is_last_submit: ->
    # if the model is last and is a submit button
    (@collection.length - @collection.indexOf(@)) is 1 and @get(Formbuilder.options.mappings.FIELD_TYPE) is 'submit_button'

class FormbuilderCollection extends Backbone.Collection
  initialize: ->
    @on 'add', @copyCidToModel

  model: FormbuilderModel

  comparator: (model) ->
    model.indexInDOM()

  copyCidToModel: (model) ->
    model.attributes.cid = model.cid

# Classes for history
class DeletedFieldModel extends Backbone.DeepModel
  sync: -> # noop

class DeletedFieldCollection extends Backbone.Collection
  model: DeletedFieldModel

class ViewFieldView extends Backbone.View
  className: "fb-field-wrapper"

  events:
    'click .subtemplate-wrapper': 'focusEditView'
    'click .js-duplicate': 'duplicate'
    'click .js-clear': 'clear'

  initialize: (options) ->
    {@parentView} = options
    @listenTo @model, "change", @render
    @listenTo @model, "remove", @remove

  render: ->
    @$el.addClass('response-field-' + @model.get(Formbuilder.options.mappings.FIELD_TYPE))
        .data('cid', @model.cid)
        .html(Formbuilder.templates["view/base#{
          if @model.is_last_submit() then '_no_duprem'
          else if !@model.is_input() then '_non_input'
          else ''
          }"]({rf: @model}))

    return @

  focusEditView: ->
    @parentView.createAndShowEditView(@model)

  clear: ->
    @parentView.handleFormUpdate()
    @parentView.deleteToStack(@model)
    #@model.destroy()

  duplicate: ->
    attrs = _.clone(@model.attributes)
    delete attrs['id']
    attrs['label'] += ' Copy'
    @parentView.createField attrs, { position: @model.indexInDOM() + 1 }


class EditFieldView extends Backbone.View
  className: "edit-response-field"

  events:
    'click .js-add-option': 'addOption'
    'click .js-remove-option': 'removeOption'
    'click .js-default-updated': 'defaultUpdated'
    'input .option-label-input': 'forceRender'

  initialize: (options) ->
    {@parentView} = options
    @listenTo @model, "remove", @remove

  render: ->
    @$el.html(Formbuilder.templates["edit/base#{if !@model.is_input() then '_non_input' else ''}"]({rf: @model}))
    rivets.bind @$el, { model: @model }
    return @

  remove: ->
    @parentView.editView = undefined
    @parentView.$el.find("[data-target=\"#addField\"]").click()
    super

  # @todo this should really be on the model, not the view
  addOption: (e) ->
    $el = $(e.currentTarget)
    i = @$el.find('.option').index($el.closest('.option'))
    options = @model.get(Formbuilder.options.mappings.OPTIONS) || []
    newOption = {label: "", checked: false}

    if i > -1
      options.splice(i + 1, 0, newOption)
    else
      options.push newOption

    @model.set Formbuilder.options.mappings.OPTIONS, options
    @model.trigger "change:#{Formbuilder.options.mappings.OPTIONS}"
    @forceRender()

  removeOption: (e) ->
    $el = $(e.currentTarget)
    index = @$el.find(".js-remove-option").index($el)
    options = @model.get Formbuilder.options.mappings.OPTIONS
    options.splice index, 1
    @model.set Formbuilder.options.mappings.OPTIONS, options
    @model.trigger "change:#{Formbuilder.options.mappings.OPTIONS}"
    @forceRender()

  defaultUpdated: (e) ->
    $el = $(e.currentTarget)

    unless @model.get(Formbuilder.options.mappings.FIELD_TYPE) == 'checkboxes' # checkboxes can have multiple options selected
      @$el.find(".js-default-updated").not($el).attr('checked', false).trigger('change')

    @forceRender()

  forceRender: ->
    @model.trigger('change')


class BuilderView extends Backbone.View
  SUBVIEWS: []

  events:
    'click .js-undo-delete': 'undoDelete'
    'click .js-save-form': 'saveForm'
    'click .fb-tabs a': 'showTab'
    'click .fb-add-field-types a': 'addField'

  initialize: (options) ->
    {selector, @formBuilder, @bootstrapData} = options

    # This is a terrible idea because it's not scoped to this view.
    if selector?
      @setElement $(selector)

    # Create the collection, and bind the appropriate events
    @collection = new FormbuilderCollection
    @collection.bind 'add', @addOne, @
    @collection.bind 'reset', @reset, @
    @collection.bind 'change', @handleFormUpdate, @
    @collection.bind 'remove add reset', @hideShowNoResponseFields, @
    @collection.bind 'remove', @ensureEditViewScrolled, @

    # Create the undo stack, and bind the appropriate events
    @undoStack = new DeletedFieldCollection
    @undoStack.bind 'add remove', @setUndoButton, @

    @render()
    @collection.reset(@bootstrapData)
    #If this is (a new form OR one without a submit button) and formbuilder is configured to add one
    if _.pathGet(@bootstrapData?[@bootstrapData?.length-1], Formbuilder.options.mappings.FIELD_TYPE) isnt 'submit_button' and
        Formbuilder.options.FORCE_BOTTOM_SUBMIT
      newSubmit = new FormbuilderModel
      setter = {}
      setter[Formbuilder.options.mappings.LABEL]       = 'Submit'
      setter[Formbuilder.options.mappings.FIELD_TYPE]  = 'submit_button'
      setter[Formbuilder.options.mappings.DESCRIPTION] = 'Submit'
      newSubmit.set(setter)
      @collection.push(newSubmit)
    @initAutosave()
    @setUndoButton()

  initAutosave: ->
    @formSaved = true
    @saveFormButton = @$el.find(".js-save-form")
    @saveFormButton.attr('disabled', true).text(Formbuilder.options.dict.ALL_CHANGES_SAVED)

    setInterval =>
      @saveForm.call(@)
    , 5000

    if Formbuilder.options.WARN_IF_UNSAVED
      $(window).bind 'beforeunload', =>
        if @formSaved then undefined else Formbuilder.options.dict.UNSAVED_CHANGES

  setUndoButton: ->
    @$undoDeleteButton = @$el.find('.js-undo-delete')
    if not @undoStack.length
      @$undoDeleteButton.attr('disabled', true)
                        .text(Formbuilder.options.dict.NOTHING_TO_UNDO)
    else
      topModel = @undoStack.at(@undoStack.length - 1).get('model')
      lastElType = topModel.get(Formbuilder.options.mappings.FIELD_TYPE)
      lastElLabel = topModel.get(Formbuilder.options.mappings.LABEL)
      @$undoDeleteButton.attr('disabled', false)
                        .text(Formbuilder.options.dict.UNDO_DELETE(lastElType, lastElLabel))

  reset: ->
    @$responseFields.html('')
    @addAll()

  render: ->
    @$el.html Formbuilder.templates['page']()

    # Save jQuery objects for easy use
    @$fbLeft = @$el.find('.fb-left')
    @$responseFields = @$el.find('.fb-response-fields')

    @bindWindowScrollEvent()
    @hideShowNoResponseFields()

    # Render any subviews (this is an easy way of extending the Formbuilder)
    new subview({parentView: @}).render() for subview in @SUBVIEWS

    return @

  bindWindowScrollEvent: ->
    $(window).on 'scroll', =>
      return if @$fbLeft.data('locked') == true
      newMargin = Math.max(0, $(window).scrollTop())
      maxMargin = @$responseFields.height()

      @$fbLeft.css
        'margin-top': Math.min(maxMargin, newMargin)

  showTab: (e) ->
    $el = $(e.currentTarget)
    target = $el.data('target')
    $el.closest('li').addClass('active').siblings('li').removeClass('active')
    $(target).addClass('active').siblings('.fb-tab-pane').removeClass('active')

    @unlockLeftWrapper() unless target == '#editField'

    if target == '#editField' && !@editView && (first_model = @collection.models[0])
      @createAndShowEditView(first_model)

  addOne: (responseField, _, options) ->
    view = new ViewFieldView
      model: responseField
      parentView: @

    #####
    # Calculates where to place this new field.
    #
    # Is this the last submit button?
    if responseField.is_last_submit() and Formbuilder.options.FORCE_BOTTOM_SUBMIT
      @$responseFields.parent().append view.render().el

    # Are we replacing a temporarily drag placeholder?
    else if options.$replaceEl?
      options.$replaceEl.replaceWith(view.render().el)

    # Are we adding to the bottom?
    else if !options.position? || options.position == -1
      @$responseFields.append view.render().el

    # Are we adding to the top?
    else if options.position == 0
      @$responseFields.prepend view.render().el

    # Are we adding below an existing field?
    else if ($replacePosition = @$responseFields.find(".fb-field-wrapper").eq(options.position))[0]
      $replacePosition.before view.render().el

    # Catch-all: add to bottom
    else
      @$responseFields.append view.render().el


  setSortable: ->
    @$responseFields.sortable('destroy') if @$responseFields.hasClass('ui-sortable')
    @$responseFields.sortable
      forcePlaceholderSize: true
      axis: 'y'
      containment: @$responseFields.parent().parent()
      placeholder: 'sortable-placeholder'
      stop: (e, ui) =>
        if ui.item.data('field-type')
          rf = @collection.create Formbuilder.helpers.defaultFieldAttrs(ui.item.data('field-type')), {$replaceEl: ui.item}
          @createAndShowEditView(rf)

        @handleFormUpdate()
        return true
      update: (e, ui) =>
        # ensureEditViewScrolled, unless we're updating from the draggable
        @ensureEditViewScrolled() unless ui.item.data('field-type')

    @setDraggable()

  setDraggable: ->
    $addFieldButtons = @$el.find("[data-field-type]")

    $addFieldButtons.draggable
      connectToSortable: @$responseFields
      helper: =>
        $helper = $("<div class='response-field-draggable-helper' />")
        $helper.css
          width: @$responseFields.width() # hacky, won't get set without inline style
          height: '80px'

        $helper

  addAll: ->
    @collection.each @addOne, @
    @setSortable()

  hideShowNoResponseFields: ->
    @$el.find(".fb-no-response-fields")[ if \
      ((@collection.length is 1 and #if there's only a mandatory submit button
        Formbuilder.options.FORCE_BOTTOM_SUBMIT and
        @collection.models[0]?.is_last_submit()) or #or if we have no fields
      @collection.length is 0) then 'show' else 'hide']()

  addField: (e) ->
    field_type = $(e.currentTarget).data('field-type')
    @createField Formbuilder.helpers.defaultFieldAttrs(field_type)

  createField: (attrs, options) ->
    rf = @collection.create attrs, options
    @createAndShowEditView(rf)
    @handleFormUpdate()

  createAndShowEditView: (model) ->
    $responseFieldEl = @$el.find(".fb-field-wrapper").filter( -> $(@).data('cid') == model.cid )
    #Set the editing classes, including fb-field-wrapper outside the list too (ad-hoc for last submit.)
    $responseFieldEl.addClass('editing').parent().parent().find(".fb-field-wrapper").not($responseFieldEl).removeClass('editing')

    if @editView
      if @editView.model.cid is model.cid
        @$el.find(".fb-tabs a[data-target=\"#editField\"]").click()
        @scrollLeftWrapper $responseFieldEl, (oldPadding? && oldPadding)
        return

      oldPadding = @$fbLeft.css('padding-top')
      @editView.remove()

    @editView = new EditFieldView
      model: model
      parentView: @

    $newEditEl = @editView.render().$el
    @$el.find(".fb-edit-field-wrapper").html $newEditEl
    @$el.find(".fb-tabs a[data-target=\"#editField\"]").click()
    @scrollLeftWrapper($responseFieldEl)
    return @

  ensureEditViewScrolled: ->
    return unless @editView
    @scrollLeftWrapper $(".fb-field-wrapper.editing")

  scrollLeftWrapper: ($responseFieldEl) ->
    @unlockLeftWrapper()
    return unless $responseFieldEl[0]
    $.scrollWindowTo ($responseFieldEl.offset().top - @$responseFields.offset().top), 200, =>
      @lockLeftWrapper()

  lockLeftWrapper: ->
    @$fbLeft.data('locked', true)

  unlockLeftWrapper: ->
    @$fbLeft.data('locked', false)

  handleFormUpdate: ->
    return if @updatingBatch
    @formSaved = false
    @saveFormButton.removeAttr('disabled').text(Formbuilder.options.dict.SAVE_FORM)

  saveForm: (e) ->
    return if @formSaved
    @formSaved = true
    @saveFormButton.attr('disabled', true).text(Formbuilder.options.dict.ALL_CHANGES_SAVED)
    @collection.sort()
    payload = JSON.stringify fields: @collection.toJSON()

    if Formbuilder.options.HTTP_ENDPOINT then @doAjaxSave(payload)
    @formBuilder.trigger 'save', payload

  doAjaxSave: (payload) ->
    $.ajax
      url: Formbuilder.options.HTTP_ENDPOINT
      type: Formbuilder.options.HTTP_METHOD
      data: payload
      contentType: "application/json"
      success: (data) =>
        @updatingBatch = true

        for datum in data
          # set the IDs of new response fields, returned from the server
          @collection.get(datum.cid)?.set({id: datum.id})
          @collection.trigger 'sync'

        @updatingBatch = undefined

  deleteToStack: (model) ->
    @undoStack.push({
      position: model.indexInDOM() #this must be called first, before the model is removed
      # model: @collection.clone(model)
      model: model.clone()
      })
    model.destroy()

  undoDelete: (e) ->
    restoree = @undoStack.pop()
    @collection.create(restoree.get('model'), {position: restoree.get('position')})

class Formbuilder
  @helpers:
    defaultFieldAttrs: (field_type) ->
      attrs = {}
      _.pathAssign(attrs, Formbuilder.options.mappings.LABEL, 'Untitled')
      _.pathAssign(attrs, Formbuilder.options.mappings.FIELD_TYPE, field_type)
      _.pathAssign(attrs, Formbuilder.options.mappings.REQUIRED, Formbuilder.options.REQUIRED_DEFAULT)

      Formbuilder.fields[field_type].defaultAttributes?(attrs) || attrs

    simple_format: (x) ->
      x?.replace(/\n/g, '<br />')

  @options:
    BUTTON_CLASS: 'fb-button'
    HTTP_ENDPOINT: ''
    HTTP_METHOD: 'POST'

    SHOW_SAVE_BUTTON: true
    WARN_IF_UNSAVED: true # this is on navigation away
    FORCE_BOTTOM_SUBMIT: true
    REQUIRED_DEFAULT: true

    UNLISTED_FIELDS: [
     'submit_button'
    ]

    mappings:
      SIZE: 'field_options.size'
      UNITS: 'field_options.units'
      LABEL: 'label'
      FIELD_TYPE: 'field_type'
      REQUIRED: 'required'
      ADMIN_ONLY: 'admin_only'
      OPTIONS: 'field_options.options'
      DESCRIPTION: 'field_options.description'
      INCLUDE_OTHER: 'field_options.include_other_option'
      INCLUDE_BLANK: 'field_options.include_blank_option'
      INTEGER_ONLY: 'field_options.integer_only'
      MIN: 'field_options.min'
      MAX: 'field_options.max'
      MINLENGTH: 'field_options.minlength'
      MAXLENGTH: 'field_options.maxlength'
      LENGTH_UNITS: 'field_options.min_max_length_units'

    dict:
      ALL_CHANGES_SAVED: 'All changes saved'
      SAVE_FORM: 'Save form'
      UNSAVED_CHANGES: 'You have unsaved changes. If you leave this page, you will lose those changes!'
      NOTHING_TO_UNDO: 'Nothing to restore'
      UNDO_DELETE: (lastElType, lastElLabel) ->
        'Undo deletion of ' + _(lastElType).capitalize() + " Field '" + _(lastElLabel).truncate(15) + "'"

  @fields: {}
  @inputFields: {}
  @nonInputFields: {}
  debug: {}

  @registerField: (name, opts) ->
    for x in ['view', 'edit']
      opts[x] = _.template(opts[x])

    opts.field_type = name

    Formbuilder.fields[name] = opts

    #register field in edit pane
    if name not in Formbuilder.options.UNLISTED_FIELDS # safety net if config is never used
      if opts.type == 'non_input'
        Formbuilder.nonInputFields[name] = opts
      else
        Formbuilder.inputFields[name] = opts

  saveForm: => #expose an instance method to manually save the data
    @mainView.saveForm()

  @config: (options) ->
    Formbuilder.options = $.extend(true, Formbuilder.options, options)

    # Set inputFields and nonInputFields to the non-unlisted fields
    if options.UNLISTED_FIELDS?
      console.log(Formbuilder.options.UNLISTED_FIELDS)
      listed_fields = _.omit(Formbuilder.fields, Formbuilder.options.UNLISTED_FIELDS)
      #clear lists used by the "Add field" view
      Formbuilder.inputFields = {}
      Formbuilder.nonInputFields = {}
      console.log(listed_fields)
      for name, data of listed_fields
        if data.type == 'non_input'
          Formbuilder.nonInputFields[name] = data
        else
          Formbuilder.inputFields[name] = data
      # Formbuilder.inputFields = _.omit(Formbuilder.inputFields, options.UNLISTED_FIELDS)
      # Formbuilder.nonInputFields = _.omit(Formbuilder.nonInputFields, options.UNLISTED_FIELDS)

  constructor: (instanceOpts={}) ->
    _.extend @, Backbone.Events
    args = _.extend instanceOpts, {formBuilder: @}
    @mainView = new BuilderView args
    @debug.BuilderView = @mainView

window.Formbuilder = Formbuilder

if module?
  module.exports = Formbuilder
else
  window.Formbuilder = Formbuilder
