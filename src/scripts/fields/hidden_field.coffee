Formbuilder.registerField 'hidden_field',

  order: 10

  type: 'non_input'

  view: """
    <label>Hidden Field:</label>
    <pre><code><%= _.escape(rf.get(Formbuilder.options.mappings.DESCRIPTION)) %></code></pre>
  """

  edit: """
    <div class='fb-edit-section-header'>Data</div>
    <textarea data-rv-input='model.<%= Formbuilder.options.mappings.DESCRIPTION %>'
      placeholder='Add a longer description to this field'></textarea>
  """

  addButton: """
    <span class='symbol'><span class='fa fa-code'></span></span> Hidden Field
  """

  defaultAttributes: (attrs) ->
    attrs.label = 'Hidden Field'
    attrs
