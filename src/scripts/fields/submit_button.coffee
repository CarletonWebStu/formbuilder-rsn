Formbuilder.registerField 'submit_button',

  order: 20

  type: 'non_input'

  view: """
    <button><%= rf.get(Formbuilder.options.mappings.DESCRIPTION) %></button>
  """

  edit: """
    <div class='fb-edit-section-header'>Button Label</div>
    <input type="text" data-rv-input='model.<%= Formbuilder.options.mappings.DESCRIPTION %>'></input>
  """

  addButton: """
    <span class='symbol'><span class='fa fa-inbox'></span></span> Submit Button
  """

  defaultAttributes: (attrs) ->
    attrs.label = 'Submit'
    attrs.field_options.description = 'Submit'
    attrs
