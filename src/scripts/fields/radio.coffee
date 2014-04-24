Formbuilder.registerField 'radio',

  order: 15

  view: """
    <%
      var optionsForLooping = rf.get(Formbuilder.options.mappings.OPTIONS) || [];
      for (var i = 0 ; i < optionsForLooping.length ; i++) {
    %>
      <div>
        <label class='fb-option'>
          <input type='radio' <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].checked && 'checked' %> onclick="javascript: return false;" />
          <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].label %>
        </label>
      </div>
    <% } %>

    <% if (rf.get(Formbuilder.options.mappings.INCLUDE_OTHER)) { %>
      <div class='other-option'>
        <label class='fb-option'>
          <input type='radio' />
          Other
        </label>

        <input type='text' />
      </div>
    <% } %>
  """

  edit: """
    <%= Formbuilder.templates['edit/options']() %>
  """
  ### was: """
    <%= Formbuilder.templates['edit/options']({ includeOther: true }) %>
  """###

  addButton: """
    <span class="symbol"><span class="fa fa-circle-o"></span></span> Multiple Choice
  """

  defaultAttributes: (attrs) ->
    _.pathAssign(attrs, Formbuilder.options.mappings.OPTIONS, [
        label: "",
        checked: false
      ,
        label: "",
        checked: false
      ])

    attrs
