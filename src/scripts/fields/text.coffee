localPrettyName = "Single Line Text"
Formbuilder.registerField 'text',

  order: 0

  view: """
    <input type='text' class='rf-size-<%= rf.get(Formbuilder.options.mappings.SIZE) %>'/>
  """

  edit: """
    <%= Formbuilder.templates['edit/defaultVal']() %>
  """
  ###was: """
    <%= Formbuilder.templates['edit/size']() %>
    <%= Formbuilder.templates['edit/min_max_length']() %>
  """###

  prettyName: localPrettyName
  addButton: "<span class='symbol'><span class='fa fa-font'></span></span> " + localPrettyName

  # defaultAttributes: (attrs) ->
  #   _.pathAssign(attrs, Formbuilder.options.mappings.SIZE, 'small')
  #
  #   attrs
#
