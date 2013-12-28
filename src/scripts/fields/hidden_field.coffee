Formbuilder.registerField 'hidden_field',

  order: 10

  type: 'non_input'

  view: """
    <label class='section-name'><%= rf.get(Formbuilder.options.mappings.LABEL) %></label>
    <pre><code><%= _.escape(rf.get(Formbuilder.options.mappings.DESCRIPTION)) %></code></pre>
  """

  edit: """
    <div class='fb-edit-section-header'>Label</div>
    <input type='text' data-rv-input='model.<%= Formbuilder.options.mappings.LABEL %>' />
    <div class='fb-edit-section-header'>Data</div>
    <textarea data-rv-input='model.<%= Formbuilder.options.mappings.DESCRIPTION %>'
      placeholder='Add some data to this hidden field'></textarea>
  """

  addButton: """
    <span class='symbol'><span class='fa fa-code'></span></span> Hidden Field
  """

  defaultAttributes: (attrs) ->
    _.pathAssign(attrs, Formbuilder.options.mappings.LABEL, 'Hidden Field')

    attrs
