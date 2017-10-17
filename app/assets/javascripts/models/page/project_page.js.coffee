#= require models/data/query
#= require models/data/project
#= require models/data/preferences
#= require models/ui/temporal
#= require models/ui/project_list
#= require models/ui/service_options_list
#= require models/ui/feedback
#= require models/ui/sitetour
#= require models/ui/granules_list

data = @edsc.models.data
ui = @edsc.models.ui
ns = @edsc.models.page

ns.ProjectPage = do (ko,
  setCurrent = ns.setCurrent
  urlUtil = @edsc.util.url
  QueryModel = data.query.CollectionQuery
  ProjectModel = data.Project
  PreferencesModel = data.Preferences
  TemporalModel = ui.Temporal
  ProjectListModel = ui.ProjectList
  SiteTourModel = ui.SiteTour
  ServiceOptionsListModel = ui.ServiceOptionsList
  FeedbackModel = ui.Feedback
  ajax=@edsc.util.xhr.ajax
  GranulesList = ui.GranulesList
) ->

  class ProjectPage
    constructor: ->
      @query = new QueryModel()
      @project = new ProjectModel(@query)
      @projectQuery =
      @id = window.location.href.match(/\/projects\/(\d+)$/)?[1]
      @bindingsLoaded = ko.observable(false)
      @preferences = new PreferencesModel()
      @workspaceName = ko.observable(null)
      @workspaceNameField = ko.observable(null)
      @projectGranules = ko.computed(@_computeProjectGranules, this, deferEvaluation: true)
      @loadingSize = ko.observable(true)
      @projectLoaded = ko.observable(@project.collections?().length > 0)
      @projectSize = ko.observable({size: 'Loading', unit: 'granule size'})
      @sizeLoaded = ko.observable(false)

      projectList = new ProjectListModel(@project)
      @ui =
        temporal: new TemporalModel(@query)
        projectList: projectList
        feedback: new FeedbackModel()
        sitetour: new SiteTourModel()

      $(window).on 'edsc.save_workspace', (e)=>
        urlUtil.saveState('/search/collections', urlUtil.currentParams(), true, @workspaceNameField())
        @workspaceName(@workspaceNameField())
        $('.save-dropdown').removeClass('open')

      setTimeout((=>
        @_loadFromUrl()
        $(window).on 'edsc.pagechange', @_loadFromUrl), 0)

      _timer = setInterval((=> @_retrieveProjectSize(_timer)), 0)

    _loadFromUrl: (e)=>
      @project.serialized(urlUtil.currentParams())
      @workspaceName(urlUtil.getProjectName())

    _computeProjectGranules: =>
      if @project.collections?().length > 0
        total = 0
        total += c.granuleCount() for c in @project.collections()
        excluded = 0
        for pg in @project.serialized().pg when pg.exclude? && @project.serialized().pg?
          excluded += pg.exclude.echo_granule_id.length
        total - excluded
      else
        'Loading'

    _retrieveProjectSize: (_timer) =>
      collectionIds = urlUtil.currentParams()['p']?.split('!')
      collectionIds?.shift()

      if @project.collections?().length == collectionIds?.length && collectionIds?.length > 0 && !@sizeLoaded()
        clearInterval(_timer)
        serialized = @project.serialized()
        p = serialized.p.split('!')
        shifted = p.shift() # remove first repeated or nil collection id
        if p.length == collectionIds.length
          data = []

          if shifted == ''
            # start from index 0
            for c, i in p
              _elem = {collection: c, granuleCount: @project.collections()[i].granuleCount() - (serialized.pg[i].exclude?.echo_granule_id.length ? 0)}
              data.push(_elem)
          else
            # start from index 1
            for c, i in p
              _elem = {collection: c, granuleCount: @project.collections()[i].granuleCount() - (serialized.pg[i + 1].exclude?.echo_granule_id.length ? 0)}
              data.push(_elem)

          @sizeLoaded(true)

          ajax
            dataType: 'json'
            type: 'post'
            url: 'project_size'
            contentType: 'application/json',
            data: JSON.stringify({'entries': data})
            success: (data) =>
              data.size = Math.ceil(data.size)
              @projectSize(data)

  setCurrent(new ProjectPage())

  exports = ProjectPage
