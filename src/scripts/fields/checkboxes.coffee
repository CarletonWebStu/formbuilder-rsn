Formbuilder.registerField 'checkboxes',

  order: 10

  view: """
    <%
        var optionsForLooping = rf.get(Formbuilder.options.mappings.OPTIONS) || [];
        for (var i = 0 ; i < optionsForLooping.length ; i++) {
    %>
      <div>
        <label class='fb-option'>
          <input type='checkbox' <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].checked && 'checked' %> onclick="javascript: return false;" />
          <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].label %>
        </label>
      </div>
    <% } %>

    <% if (rf.get(Formbuilder.options.mappings.INCLUDE_OTHER)) { %>
      <div class='other-option'>
        <label class='fb-option'>
          <input type='checkbox' />
          Other
        </label>

        <input type='text' />
      </div>
    <% } %>
  """

  edit: """
    <%= Formbuilder.templates['edit/options']() %>
  """

  ###was: """
    <%= Formbuilder.templates['edit/options']({ includeOther: true }) %>
  """###

  addButton: """
    <span class="symbol"><span class="fa fa-check-square-o"></span></span> Checkboxes
  """

  defaultAttributes: (attrs) ->
    _.pathAssign(attrs, Formbuilder.options.mappings.OPTIONS, Formbuilder.generateDefaultOptionsArray())

    attrs
